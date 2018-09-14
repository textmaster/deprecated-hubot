const _ = require('underscore');
const moment = require('moment');

const branchLink = branch =>
  `[${branch.branch_name}](${branch.build_url})`;

const listAvailableServices = projects => {
  let message = "";
  _.chain(projects)
    .sortBy(project => project.name)
    .each(project => {
      let master_branch = _.findWhere(project.branches, {
        branch_name: 'master',
      });
      if (master_branch) {
        return (message += `* [${master_branch.result}] ${project.name}\n`);
      } else {
        return (message += `* [${project.branches[0].result}] ${project.name}\n`);
      }
    });
  return message;
}

const listAvailableBranches = branches => {
  let message = ""
  _.chain(branches)
    .sortBy(branch => branch.branch_name)
    .each(
      branch => (message += `* [${branch.result}] ${branch.branch_name}\n`),
    );
  return message;
};

const listAvailableServers = servers => {
  let message = "";
  _.chain(servers)
    .sortBy(server => server.name)
    .each(server => (message += `* ${server.name}\n`));
  return message;
}

const startMessage = d =>
  `Looking for ${d.serviceName}'s build status...`;

const deployLink = status => `[#${status.number}](${status.html_url})`;
const lastDeployed = status => `Deploy ${deployLink(status)} **${status.result}** ${status.finished_at && moment(status.finished_at).fromNow()}`;
const formatCommitMessage = message => `${'`'}${(message || '').split('\n')[0].substring(0, 80)}${'`'}`;
const commitLink = commit => `[${commit.id.substring(0,7)}](${commit.url})`
const commitInfo = commit => `${commitLink(commit)} ${commit.author_name} ${formatCommitMessage(commit.message)}`;
const formatPR = ({html_url: url, number, title}) => `[PR #${number} ${title}](${url})`;
const previousDeploy = status => `*Previous ${lastDeployed(status)}* - ${commitInfo(status.commit)}`;
const buildLink = status => `[#${status.build_number}](${status.build_url})`;

const targetDeploy = d => `**Building ${d.branch.branch_name}** ${buildLink(d.branch)} ${commitLink(d.branch.commit)} ${commitDiff(d.commits)}`;

const commitDiff = commits => `[Ahead ${commits.ahead_by} / Behind ${commits.behind_by}](${commits.html_url}) \n ${commitsSummary(commits.commits)}`;
const commitsSummary = commits => commits.reverse().slice(0, 5).map(c => `* ${commitSummary(c)}`).join('\n') + (
  commits.length > 5 ? `\n* and ${commits.length - 5} more..` : ''
);
// Github commit object (different to semaphore objects above)
const commitSummary = commit => `[${commit.sha.substring(0,7)}](${commit.html_url}) ${commit.commit.author.name} ${formatCommitMessage(commit.commit.message)}`;

const buildStatus = (d) =>
  `\nBuild status is **${d.buildStatus}**`;

const buildStatusMessage = d =>
  `${previousDeploy(d.deployTarget.serverStatus)}\n\n${targetDeploy(d)}\n${buildStatus(d)}`;

const skipTestMessage = d =>
  `Force deploy specified - scheduling deployment of ${branchLink(d.branch)} immediately`;

const rebuildingMessage = d =>
  `Rebuilding branch ${branchLink(d.branch)}`

const waitingMessage = d =>
  `Scheduling deployment of branch ${branchLink(d.branch)} as soon as build has passed`

const deployingMessage = d =>
 `Deploying ${branchLink(d.branch)} on ${d.server.name}`

const deployedMessage = d =>
 `Deployed ${branchLink(d.branch)} on ${d.server.name}`

const cancelMessage = d =>
  `Deploy ${d.serviceName} ${d.serverName} cancelled`;

const buildFailedMessage = d =>
  `Cannot deploy ${branchLink(d.branch)} becuase build has failed`

const projectNotFoundMessage = (d, e) =>
 `Cannot find matching service "${d.serviceName}". Available services are:\n${listAvailableServices(e.projects)}`;

const buildNotFoundMessage = (d, e) =>
  `Cannot find last deployed build for ${d.serviceName} ${d.serverName}`

const branchNotFoundMessage = (d, e) =>
  `Cannot find branch ${d.branchName} in ${d.project.name}'s branches.` +
  `Available branches are:\n${listAvailableBranches(d.project.branches)}`

const serverNotFoundMessage = (d, e) =>
  `Cannot find server ${d.serverName}. Available servers are:\n${listAvailableServers(e.servers)}`;

const unknownErrorMessage = (d, e) =>
  `Unknown error ${e.message} ${e} \n ${"```\n" + e.stack + "```\n"}`;

const deploymentFailedMessage = (d, e) =>
  `Deploy ${d.serviceName} ${d.serverName} ${e.deploy.number} failed`;

module.exports = {
  startMessage,
  buildStatusMessage,
  skipTestMessage,
  rebuildingMessage,
  waitingMessage,
  deployingMessage,
  cancelMessage,
  buildFailedMessage,
  projectNotFoundMessage,
  buildNotFoundMessage,
  branchNotFoundMessage,
  serverNotFoundMessage,
  unknownErrorMessage,
  deploymentFailedMessage,
  deployedMessage,
};
