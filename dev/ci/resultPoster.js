/*eslint-env node*/

exports.postPreCheckResult = ({ github, context, output }) => {
    const { owner, repo } = context.repo;
    const { title, summary, text, conclusion } = output;

    return github.checks.create({
        owner, repo,
        name: 'Release Pre-Check',
        head_sha: context.sha,
        status: 'completed',
        conclusion,
        output: {
            title: 'Logs for Pre-Check: ' + title,
            summary, text
        },
        completed_at: new Date().toISOString(),
    })
}
