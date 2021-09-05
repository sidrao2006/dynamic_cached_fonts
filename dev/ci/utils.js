/*eslint-env node*/

exports.getChangedFiles = async ({ github, context }) => {
  const listFilesOptions = github.pulls.listFiles.endpoint.merge({
    owner: context.repo.owner,
    repo: context.repo.repo,
    pull_number: context.payload.pull_request.number,
  });

  const listFilesResponse = await github.paginate(listFilesOptions);

  return listFilesResponse.map(file => file.filename);
}
