const {
  ProjectNotFound,
} = require('../../errors');
const moment = require('moment');
const _ = require('underscore');
const projectNotFoundMessage = e => `Project Not Found ${e.name}`;
const unknownErrorMessage = e => `Error getting server status:\n Unknown Error ${e}`;

const serverLink = (server, status) => status.server_html_url ? `[${server.name}](${status.server_html_url})` : server.name;
const deployLink = status => `[#${status.number}](${status.html_url})`;
const buildLink = build => `[Build #${build.number}](${build.html_url})`;

const lastDeployed = status => status.finished_at ? `Deploy ${deployLink(status)} **${status.result}** ${moment(status.finished_at).fromNow()}` : "";
const formatCommitMessage = message => `${'`'}${(message || '').split('\n')[0].substring(0, 80)}${'`'}`;
const commitInfo = commit => `[${commit.id.substring(0,7)}](${commit.url}) ${commit.author_name} ${formatCommitMessage(commit.message)}`;
const formatPR = ({html_url: url, number, title}) => `[PR #${number} ${title}](${url})`;
const buildInfo = (build, pr) => `*${build.branch_name}* ${buildLink(build)} **${build.result}** ${pr ? formatPR(pr) : ''}`;

const formatServerBuild = ({server, status, build, pr}) => `**${serverLink(server, status)}**\n${lastDeployed(status)}\n${build ? buildInfo(build, pr) : '*No build information*'}\n${status.commit ? commitInfo(status.commit) : ''}`;

const formatServer = (statusObj, server) => {
  const {status, build, pr} = statusObj.serverStatus[server.id];
  return formatServerBuild({server, status, build, pr});
};

const listServers = status => _.sortBy(status.servers, ({name}) => name).map((server) => `${formatServer(status, server)}`).join("\n\n");

const serverStatusMessage = status => `Current server status for ${status.serviceName}: \n${listServers(status)}`;

function watchStatus({status, msg}) {
  status.on('complete', () => msg.send(serverStatusMessage(status)));

  status.on('error', (e) => {
    switch(e.constructor) {
      case ProjectNotFound:
        msg.send(projectNotFoundMessage(status, e));
        break
      default:
        msg.send(unknownErrorMessage(status, e));
        break;
    }
  });
}

module.exports = watchStatus;
