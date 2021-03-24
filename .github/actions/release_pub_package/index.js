import * as core from '@actions/core'
import { exec } from '@actions/exec'
import * as github from '@actions/github'
import * as tc from '@actions/tool-cache'
import * as auth from '@octokit/auth-action'
import * as rest from '@octokit/rest'
import parseChangelog from 'changelog-parser'
import * as fs from 'fs'

// Latest Stable Version (at the time of release) that support all required features.

const flutterWinDownloadUrl = 'https://storage.googleapis.com/flutter_infra/releases/stable/windows/flutter_windows_2.0.3-stable.zip'
const flutterMacOSDownloadUrl = 'https://storage.googleapis.com/flutter_infra/releases/stable/macos/flutter_macos_2.0.3-stable.zip'
const flutterLinuxDownloadUrl = 'https://storage.googleapis.com/flutter_infra/releases/stable/linux/flutter_linux_2.0.3-stable.tar.xz'

// Get inputs from workflow

let inputs

getActionInputs()

// Setup Github Rest API

const changelogFile = inputs.changelogFilePath ?? `${process.env.GITHUB_WORKSPACE}/CHANGELOG.md`

// Get latest version and release notes from changelog

addFakeChangelogHeading()

let version, body

parseChangelog(changelogFile, (_, changelog) => {
   version = changelog.versions[0].version
   body = changelog.versions[0].body
})

// Check if latest version in changelog has already been released

if (version === inputs.previousVersion) {
   core.setFailed(
      `No new version found .Latest version in Changelog (${version}) is the same as the previous version.`
   )
}

const octokit = setUpAuth()

// Create a release

createRelease()

// Set up the Flutter SDK

setUpFlutterSDK()

// Setup auth for pub

setUpPubAuth()

// Publish package

publishPackageToPub()

// Helper functions

async function setUpAuth() {
   const authentication = auth.createActionAuth()

   return new rest.Octokit({
      auth: await authentication()
   })
}

async function getActionInputs() {
   try {
      inputs.previousVersion = core.getInput('previous-version') || await getLatestReleaseVersion()

      inputs.changelogFilePath = core.getInput('changelog-file')

      inputs.isDraft = core.getInput('is-draft').toUpperCase() === 'TRUE'

      inputs.preReleaseScript = core.getInput('pre-release-script')
      inputs.postReleaseScript = core.getInput('post-release-script')

      inputs.prePublishScript = core.getInput('pre-publish-script')
      inputs.postPublishScript = core.getInput('post-publish-script')

      inputs.shouldRunPubScoreTest = core.getInput('should-run-pub-score-test').toUpperCase() === 'TRUE'
      inputs.pubScoreMinPoints = Number.parseInt(core.getInput('pub-score-min-points'))

      inputs.accessToken = core.getInput('access-token', { required: true })
      inputs.refreshToken = core.getInput('refresh-token', { required: true })
      inputs.idToken = core.getInput('id-token', { required: true })
      inputs.tokenEndpoint = core.getInput('token-endpoint', { required: true })
      inputs.expiration = core.getInput('expiration', { required: true })
   } catch (err) {
      core.setFailed(err)
   }
}

async function getLatestReleaseVersion() {
   const repo = github.context.repo

   const latestRelease = (await octokit).repos.getLatestRelease({
      owner: repo.owner,
      repo: repo
   })

   return (await latestRelease).data.tag_name.replace('v', '')
}

function addFakeChangelogHeading() {
   const data = fs.readFileSync(changelogFile)
   const fd = fs.openSync(changelogFile, 'w+')
   const buffer = new Buffer.from('# Fake Heading\n\n')

   fs.writeSync(fd, buffer, 0, buffer.length, 0) // write new data

   fs.appendFileSync(changelogFile, data) // append old data

   fs.closeSync(fd)
}

function getCommand(commandScript) {
   const commandAndArgs = commandScript.split(' ')

   return {
      commandLine: commandAndArgs[0],
      args: commandAndArgs.slice(1)
   }
}

async function createRelease() {
   const preReleaseCommand = getCommand(inputs.preReleaseScript)
   const postReleaseCommand = getCommand(inputs.postReleaseScript)
   const repo = github.context.repo

   await exec(preReleaseCommand.commandLine, preReleaseCommand.args)

   await (await octokit).repos.createRelease({
      owner: repo.owner,
      repo: repo,
      tag_name: `v${version}`,
      target_commitish: github.context.sha,
      body: body,
      draft: inputs.isDraft,
      prerelease: version.contains('-')
   })

   await exec(postReleaseCommand.commandLine, postReleaseCommand.args)
}

async function setUpFlutterSDK() {
   core.exportVariable('FLUTTER_ROOT', `${process.env.HOME}/flutter`)

   const toolLocation = tc.find('flutter', '2.x') || process.env.FLUTTER_ROOT

   if (process.platform === 'win32') {
      const flutterPath = await tc.downloadTool(flutterWinDownloadUrl)
      await tc.extractZip(flutterPath, process.env.FLUTTER_ROOT)

      tc.cacheDir(process.env.FLUTTER_ROOT, 'flutter', '2.0.3')
   } else if (process.platform === 'darwin') {
      const flutterPath = await tc.downloadTool(flutterMacOSDownloadUrl)
      await tc.extractZip(flutterPath, process.env.FLUTTER_ROOT)

      tc.cacheDir(process.env.FLUTTER_ROOT, 'flutter', '2.0.3')
   } else {
      const flutterPath = await tc.downloadTool(flutterLinuxDownloadUrl)
      await tc.extractTar(flutterPath, process.env.FLUTTER_ROOT)

      tc.cacheDir(process.env.FLUTTER_ROOT, 'flutter', '2.0.3')
   }

   core.addPath(`${toolLocation}/bin/flutter`)
}

async function publishPackageToPub() {
   const prePublishCommand = getCommand(inputs.prePublishScript)
   const postPublishCommand = getCommand(inputs.postPublishScript)

   await exec(prePublishCommand.commandLine, prePublishCommand.args)

   await runPanaTest()

   await exec('flutter', ['pub', 'publish', '--force'])

   await exec(postPublishCommand.commandLine, postPublishCommand.args)
}

async function runPanaTest() {
   if (inputs.shouldRunPubScoreTest) {
      let panaResult

      await exec('flutter', ['pub', 'global', 'activate', 'pana'])

      await exec('flutter', ['pub', 'global', 'run', 'pana', process.env.GITHUB_WORKSPACE, '--json', '--no-warning'], {
         listeners: {
            stdout: data => { panaResult += data.toString() },
            stderr: data => { panaResult += data.toString() }
         }
      })

      const resultArr = panaResult.split(/\r?\n/)

      const panaReport = JSON.parse(resultArr[resultArr - 1]).report

      if (isNaN(inputs.pubScoreMinPoints)) core.setFailed('run-pub-score-test was set to true but no value for pub-score-min-points was provided')

      if (panaReport.scores.grantedPoints < inputs.pubScoreMinPoints) {
         for (const test in panaReport.sections) {
            if (test.status !== 'passed') core.warning(test.title + '\n\n\n' + test.summary)
         }
         core.error('Pub score test failed')
      }
   }
}

function setUpPubAuth() {
   const credentials = {
      accessToken: inputs.accessToken,
      refreshToken: inputs.refreshToken,
      idToken: inputs.idToken,
      tokenEndpoint: inputs.tokenEndpoint,
      scopes: [
         'https://www.googleapis.com/auth/userinfo.email',
         'openid'
      ],
      expiration: inputs.expiration
   }

   if (process.platform === 'win32') fs.writeFile(`${process.env.APPDATA}/Pub/Cache/credentials.json`, credentials)
   else fs.writeFile(`${process.env.HOME}/.pub-cache/credentials.json`, credentials)
}
