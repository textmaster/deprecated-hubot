// Description:
//   Notify flow and users on deployments
//
// Author:
//   gottfrois

const _ = require('underscore');
const {
  fetchBuildUsingBuildUrl,
  fetchBuild,
  fetchDeployment,
  buildHistory
} = require('../lib/semaphore');

module.exports = function (robot) {
  const Subscriptions = require('../lib/subscriptions')(robot);

  const fetchBuildHistory = async (deployment, page) => {
    const payload = await buildHistory(deployment.project_hash_id, deployment.branch_name, { page: page });
    return payload.builds;
  }

  const aggregateDeployedCommitsBetweenBuilds = async (deployment, previousBuild, latestBuild) => {
    const previousBuildNumber = previousBuild.number;
    const lastestBuildNumber  = latestBuild.number;

    if (previousBuildNumber == lastestBuildNumber) {
      return [deployment.commit];
    }

    const pages  = [1, 2, 3, 4, 5];
    const builds = await Promise.all(pages.map(async (page) => {
      return fetchBuildHistory(deployment, page);
    }))

    return _.chain(builds)
     .flatten()
     .filter(function(build) {
       return build.build_number > previousBuildNumber && build.build_number <= lastestBuildNumber;
     })
     .map(function(build) {
       return build.commit;
     })
     .value();
  }

  const formatName = (name) => {
    return `@${name}`;
  }

  const lookupNamesFromSubscriptions = (event) => {
    return _.keys(Subscriptions.subscriptions(event));
  }

  const buildNotificationsMessage = (events) => {
    return _.chain(events)
     .map(lookupNamesFromSubscriptions)
     .flatten()
     .uniq()
     .map(formatName)
     .value()
     .join(', ');
  }

  const buildCommitMessage = (commit) => {
    return `* [${commit.id.substring(0, 8)}](${commit.url}) ${commit.message} by ${commit.author_name}`;
  }

  const buildMessage = (deployment, commits, events) => {
    const messages = [];

    // Title
    message.push(`Semaphore ${deployment.result} to deployed on ${deployment.server_name}`)
    // Commits
    messages.push(_.map(commits, buildCommitMessage))
    // Users to notify
    messages.push("");
    messages.push(buildNotificationsMessage(events));

    return _.flatten(messages).join("\n");
  }

  const notify = (deployment, commits, events) => {
    const message = buildMessage(deployment, commits, events);
    robot.messageRoom('Main', message);
  }

  robot.on('semaphore-deploy', async (deployment) => {
    if (deployment.server_name == "production") {
      const previousDeployment = await fetchDeployment(deployment.project_hash_id, deployment.server_name, deployment.number - 1);
      const previousBuild = await fetchBuildUsingBuildUrl(previousDeployment.build_url);
      const latestBuild = await fetchBuild(deployment.project_hash_id, deployment.branch_name, deployment.build_number);
      const commits = await aggregateDeployedCommitsBetweenBuilds(deployment, previousBuild, latestBuild);

      notify(deployment, commits, [
        `semaphore.${deployment.event}.${deployment.result}`,
        `semaphore.${deployment.event}.${deployment.number}`
      ]);

      Subscriptions.unsubscribeAllKeysFromEvent(`semaphore.${deployment.event}.${deployment.number}`);
    }
  });
}
