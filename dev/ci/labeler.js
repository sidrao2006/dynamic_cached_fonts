/*eslint-env node*/

exports.addRevertLabel = async ({ github, context }) => {
  const utils = require('./utils.js');
  const { owner, repo } = context.repo;

  if (await utils.PRTitleIncludes({ github, context }, "Revert"))
    github.rest.issues.addLabels({
      owner, repo,
      issue_number: context.payload.pull_request.number,
      labels: ['revert :rewind:'],
    });
}

exports.isRelease = async ({ github, context }) => {
  const utils = require('./utils.js');

  const commitMessages = utils.getPRCommitMessages({ github, context });

  return utils.PRTitleIncludes({ github, context }, "Release")
    || commitMessages.some(message =>/^release.*:.*/.test(message));
}

exports.addReleaseLabel = async ({
  github,
  context,
  workflow: workflow_id
}) => {
  const { owner, repo } = context.repo;

  if (await this.isRelease({ github, context })) {
    await github.rest.issues.addLabels({
      owner, repo,
      issue_number: context.payload.pull_request.number,
      labels: ['release :tada:'],
    });

    await github.rest.actions.createWorkflowDispatch({
      owner, repo, workflow_id,
      ref: context.ref,
    });
  }
}
