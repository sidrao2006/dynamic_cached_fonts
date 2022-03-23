/*eslint-env node*/

exports.getPRCommitMessages = async ({ github, context }) => {
  const { data: commits } = await github.rest.pulls.listCommits({
    owner: context.repo.owner,
    repo: context.repo.repo,
    pull_number: context.payload.pull_request.number,
  });

  return commits.map(commit => commit.commit.message);
}

exports.PRTitleIncludes = async ({ github, context }, title) => {
  const { data: pr } = await github.rest.pulls.get({
    owner: context.repo.owner,
    repo: context.repo.repo,
    pull_number: context.payload.pull_request.number,
  });

  return pr.title.includes(title);
}