/*eslint-env node*/

exports.postPreCheckResult = ({ github, context, output }) => {
    return github.checks.create({
        owner: context.repo.owner,
        repo: context.repo.repo,
        name: 'Release Pre-Check',
        head_sha: context.sha,
        status: 'completed',
        conclusion: output.conclusion,
        output: {
            title: 'Logs for Pre-Check: ' + output.title,
            summary: output.summary,
            text: output.logs,
        },
        completed_at: new Date().toISOString(),
    })
}
