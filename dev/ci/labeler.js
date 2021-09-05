/*eslint-env node*/

exports.addRevertLabel = async ({ github, context }) => {
  const { data: pr } = await github.pulls.get({
    owner: context.repo.owner,
    repo: context.repo.repo,
    pull_number: context.payload.pull_request.number,
  });

  if (pr.title.includes("Revert")) github.issues.addLabels({
    owner: context.repo.owner,
    repo: context.repo.repo,
    issue_number: context.payload.pull_request.number,
    labels: ['revert :rewind:'],
  });
}

exports.wereRequiredFilesModified = async ({ 
  github,
  context,
  requiredFiles = ['CHANGELOG.md', 'pubspec.yaml', 'example/pubspec.lock']
}) => {
  const utils = require('utils.js');

  const changedFiles = await utils.getChangedFiles({ github, context });

  return requiredFiles.every(file => changedFiles.includes(file));
}

exports.addReleaseLabel = async ({ github, context, workflow }) => {
  if (await this.wereRequiredFilesModified({ github, context })) {
    await github.issues.addLabels({
      owner: context.repo.owner,
      repo: context.repo.repo,
      issue_number: context.payload.pull_request.number,
      labels: ['release :tada:'],
    });

    await github.actions.createWorkflowDispatch({
      owner: context.repo.owner,
      repo: context.repo.repo,
      workflow_id: workflow,
      ref: github.ref,
    });
  }
}
