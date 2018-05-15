// Description:
//   Testing c66

const moment = require('moment');
const { getDeployBranch, getLatestDeploy, STACKS } = require('../lib/cloud66');
const { findPRForBranch, findCommit } = require('../lib/github');
const sendEditableReply = require('../lib/flowdock/editableMessage');

module.exports = function (robot) {
  robot.respond(/list test server branches/, async (res) => {
    const msg = await sendEditableReply(res, ':parrot:');

    const stacks = STACKS.map(stack => ({...stack}));
    const findStack = (id) => stacks.find(stack => stack.id == id);

    const formatBranch = (branch) =>
      `[${branch}](https://github.com/textmaster/TextMaster.com/tree/${branch}) `

    const formatCommitHash = (commit) =>
      `[${commit.substring(0, 7)}](https://github.com/textmaster/TextMaster.com/commit/${commit}) `

    const formatCommit = ({ author: { name }, message }) =>
      `${name} \`${(message || '').split("\n")[0].substring(0, 80)}\``

    const formatStack = ({name, branch, commitHash, commit, deployedAt, pr}) =>
      `- **${name}**` +
      (branch ? ` - ${formatBranch(branch)}` : '') +
      (pr ? ` (${formatPR(pr)})` : '') +
      "\n" +
      (deployedAt ? ` *deployed ${moment(deployedAt).fromNow()}*` : '') +
      "\n" +
      (commitHash ? `@ ${formatCommitHash(commitHash)}` : '') +
      (commit ? formatCommit(commit) : '') +
      "\n";

    const formatPR = ({ url, number }) =>
      `[#${number}](${url}) `

    const formatResponse = () =>
      stacks.sort(
        ({name: a}, {name: b}) => a.localeCompare(b)
      ).map(formatStack).join("\n");

    const update = () => msg.edit(formatResponse() + "\n:parrot:");
    const finish = () => msg.edit(formatResponse() + "\n:bot:");

    try {
      await Promise.all(stacks.map(async ({id}) => {
        const stack = findStack(id);

        const branch = await getDeployBranch(id);
        stack.branch = branch;
        await update();

        const deploy = await getLatestDeploy(id);
        stack.deployedAt = deploy.finished_at;
        await update();

        if(branch != 'master') {
          stack.commitHash = deploy.git_hash;

          const owner = 'textmaster';
          const repo = 'textmaster.com';

          stack.commit = await findCommit({owner, repo, commit_sha: stack.commitHash});
          await update()

          const pr = await findPRForBranch({owner, repo, branch })
          stack.pr = pr;
          await update();
        }
      }))
      finish();
      console.log(formatResponse());
    } catch (e) {
      res.send(`Something went wrong ${e.toString()}`);
    }
  });

  robot.respond(/test edit/, async (res) => {
    const msg = await sendEditableReply(res, "Reply");
    await msg.edit("Edited");
  });
}
