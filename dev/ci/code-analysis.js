const cliMarkdown = require('cli-markdown');

const { PANA_RESULT_JSON, PUB_SCORE_MIN_POINTS } = process.env;

const output = JSON.parse(PANA_RESULT_JSON),
    minScore = Number.parseInt(PUB_SCORE_MIN_POINTS)
const score = output.scores.grantedPoints,
    sections = output.report.sections;

for (const test of sections) {
    if (test.status !== 'passed') {
        core.warning(test.title)
        console.log('\n\n\n' + cliMarkdown(test.summary))
    } else console.log(test.title + '\n\n\n' + cliMarkdown(test.summary))
}

if(score < minScore) core.setFailed(`Pub score test failed. Achieved score of ${score} is less than expected minimum score of ${minScore}`)

