import * as core from '@actions/core'
import * as exec from '@actions/exec'
import * as github from '@actions/github'
import * as tc from '@actions/tool-cache'
import { Octokit } from '@octokit/action'
import parseChangelog from 'changelog-parser'
import fs from 'fs'

// Latest Stable Flutter Version (at the time of release) that support all required features.

const flutterWinDownloadUrl = 'https://storage.googleapis.com/flutter_infra/releases/stable/windows/flutter_windows_2.0.3-stable.zip'
const flutterMacOSDownloadUrl = 'https://storage.googleapis.com/flutter_infra/releases/stable/macos/flutter_macos_2.0.3-stable.zip'
const flutterLinuxDownloadUrl = 'https://storage.googleapis.com/flutter_infra/releases/stable/linux/flutter_linux_2.0.3-stable.tar.xz'

async function run() {
   const octokit = new Octokit()

   // Get inputs from workflow

   const inputs = await getActionInputs(octokit)

   // Get Changelog file path

   const changelogFile = inputs.changelogFilePath || `${process.env.GITHUB_WORKSPACE}/CHANGELOG.md`

   // Get latest version and release notes from changelog

   addFakeChangelogHeading(changelogFile)

   let version, body

   await parseChangelog(changelogFile, (_, changelog) => {
      version = changelog.versions[0].version
      body = changelog.versions[0].body
   })

   // Check if latest version in changelog has already been released

   if (version === inputs.previousVersion) {
      core.warning(
         `No new version found. Latest version in Changelog (${version}) is the same as the previous version.`
      )
      process.exit(0)
   }

   // Create a release

   await createRelease(octokit, {
      preReleaseCommand: inputs.preReleaseCommand,
      postReleaseCommand: inputs.postReleaseCommand,
      isDraft: inputs.isDraft,
      version: version,
      body: body
   })

   // Set up the Flutter SDK

   await setUpFlutterSDK()

   // Publish package

   await publishPackageToPub(inputs)
}

process.on('unhandledRejection', err => { throw err })

run()

// Helper functions

async function getActionInputs(octokit) {
   const inputs = {}

   try {
      inputs.previousVersion = core.getInput('previous-version') || await getLatestReleaseVersion(octokit)

      inputs.changelogFilePath = core.getInput('changelog-file')

      inputs.isDraft = core.getInput('is-draft').toUpperCase() === 'TRUE'

      inputs.preReleaseCommand = core.getInput('pre-release-command')
      inputs.postReleaseCommand = core.getInput('post-release-command')

      inputs.prePublishCommand = core.getInput('pre-publish-command')
      inputs.postPublishCommand = core.getInput('post-publish-command')

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

   return inputs
}

async function getLatestReleaseVersion(octokit) {
   const repo = github.context.repo

   const releases = await octokit.rest.repos.listReleases({
      owner: repo.owner,
      repo: repo.repo
   })

   return releases.data.length > 0
      ? releases.data[0].tag_name.replace('v', '')
      : '0.0.0' // undefined or null can also be returned from this step
}

function addFakeChangelogHeading(changelogFile) {
   const data = fs.readFileSync(changelogFile)
   const fd = fs.openSync(changelogFile, 'w+')
   const buffer = new Buffer.from('# Fake Heading\n\n')

   fs.writeSync(fd, buffer, 0, buffer.length, 0) // write new data

   fs.appendFileSync(changelogFile, data) // append old data

   fs.closeSync(fd)
}

async function execCommand(command) {
   if (command) {
      const commandAndArgs = command.split(' ')

      const parsedCommand = {
         commandLine: commandAndArgs[0],
         args: commandAndArgs.slice(1)
      }

      await exec.exec(parsedCommand.commandLine, parsedCommand.args)
   }
}

async function createRelease(octokit = new Octokit(), {
   preReleaseCommand,
   postReleaseCommand,
   isDraft,
   version,
   body
}) {
   await execCommand(preReleaseCommand)

   const repo = github.context.repo
   await octokit.rest.repos.createRelease({
      owner: repo.owner,
      repo: repo.repo,
      name: `v${version}`,
      tag_name: `v${version}`,
      target_commitish: github.context.sha,
      body: body,
      draft: isDraft,
      prerelease: version.includes('-')
   })

   await execCommand(postReleaseCommand)
}

async function setUpFlutterSDK() {
   core.exportVariable('FLUTTER_ROOT', `${process.env.HOME}/flutter`)

   const cachedTool = tc.find('flutter', '2.x')

   if (!cachedTool) {
      if (process.platform === 'win32') {
         const flutterPath = await tc.downloadTool(flutterWinDownloadUrl)
         await tc.extractZip(flutterPath, process.env.HOME)

         tc.cacheDir(process.env.FLUTTER_ROOT, 'flutter', '2.0.3')
      } else if (process.platform === 'darwin') {
         const flutterPath = await tc.downloadTool(flutterMacOSDownloadUrl)
         await tc.extractZip(flutterPath, process.env.HOME)

         tc.cacheDir(process.env.FLUTTER_ROOT, 'flutter', '2.0.3')
      } else {
         const flutterPath = await tc.downloadTool(flutterLinuxDownloadUrl)
         await tc.extractTar(flutterPath, process.env.HOME, 'x')

         tc.cacheDir(process.env.FLUTTER_ROOT, 'flutter', '2.0.3')
      }
   }

   core.addPath(`${cachedTool || process.env.FLUTTER_ROOT}/bin`)
}

async function publishPackageToPub(inputs) {
   await execCommand(inputs.prePublishCommand)

   if (inputs.shouldRunPubScoreTest) await runPanaTest(inputs.pubScoreMinPoints)

   // Setup auth for pub

   setUpPubAuth({
      accessToken: inputs.accessToken,
      refreshToken: inputs.refreshToken,
      idToken: inputs.idToken,
      tokenEndpoint: inputs.tokenEndpoint,
      expiration: inputs.expiration
   })

   await exec.exec('flutter', ['pub', 'publish', '--force'])

   await execCommand(inputs.postPublishCommand)
}

function setUpPubAuth({
   accessToken,
   refreshToken,
   idToken,
   tokenEndpoint,
   expiration
}) {
   const credentials = {
      accessToken: accessToken,
      refreshToken: refreshToken,
      idToken: idToken,
      tokenEndpoint: tokenEndpoint,
      scopes: [
         'openid',
         'https://www.googleapis.com/auth/userinfo.email'
      ],
      expiration: Number.parseInt(expiration)
   }

   if (process.platform === 'win32') {
      const pubCacheDir = `${process.env.APPDATA}/Pub/Cache`

      if (!fs.existsSync(pubCacheDir)) fs.mkdirSync(pubCacheDir)

      fs.writeFileSync(`${pubCacheDir}/credentials.json`, JSON.stringify(credentials))
   } else {
      const pubCacheDir = `${process.env.HOME}/.pub-cache`

      if (!fs.existsSync(pubCacheDir)) fs.mkdirSync(pubCacheDir)

      fs.writeFileSync(`${pubCacheDir}/credentials.json`, JSON.stringify(credentials))
   }

   console.log(fs.readFileSync(`${process.env.HOME}/.pub-cache/credentials.json`).toString())
}

async function runPanaTest(pubScoreMinPoints) {
   let panaOutput = ''

   await exec.exec('flutter', ['pub', 'global', 'activate', 'pana'])

   await exec.exec('flutter', ['pub', 'global', 'run', 'pana', process.env.GITHUB_WORKSPACE, '--json', '--no-warning'], {
      listeners: {
         stdout: data => { if (data.toString()) panaOutput += data.toString() }
      }
   })

   if (panaOutput.includes('undefined')) panaOutput = panaOutput.replace('undefined', '')

   const panaResult = JSON.parse(panaOutput)

   if (isNaN(pubScoreMinPoints)) core.setFailed('run-pub-score-test was set to true but no value for pub-score-min-points was provided')

   if (panaResult.scores.grantedPoints < pubScoreMinPoints) {
      for (const test in panaResult.report.sections) {
         if (test.status !== 'passed') core.warning(test.title + '\n\n\n' + test.summary)
      }
      core.error('Pub score test failed')
   }
}
