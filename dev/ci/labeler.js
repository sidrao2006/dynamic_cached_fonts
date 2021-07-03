exports.addRevertLabel = ({ github, context }) => {
    const { data: pr } = await github.pulls
        .get({
          owner: context.repo.owner,
          repo: context.repo.repo,
          pull_number: context.payload.pull_request.number,
        })

    if (pr.title.includes("Revert")) {
        github.issues.addLabels({
            owner: context.repo.owner,
            repo: context.repo.repo,
            issue_number: context.payload.pull_request.number,
            labels: ['revert :rewind:'],
        });
    }
}

exports.addReleaseLabel = async ({ github, context }) => {
    const requiredFiles = [ 'CHANGELOG.md', 'pubspec.yaml', 'example/pubspec.lock' ]

    const listFilesOptions = github.pulls.listFiles.endpoint.merge({
      owner: context.repo.owner,
      repo: context.repo.repo,
      pull_number: context.payload.pull_request.number,
    });

    const listFilesResponse = await github.paginate(listFilesOptions);
    const changedFiles = listFilesResponse.map(file => file.filename);

    if ( requiredFiles.every(file => changedFiles.includes(file)) ) {
      github.issues.addLabels({
        owner: context.repo.owner,
        repo: context.repo.repo,
        issue_number: context.payload.pull_request.number,
        labels: ['release :tada:'],
      });
    }
}