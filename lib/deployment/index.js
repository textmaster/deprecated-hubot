module.exports = {
  getDeploymentService: require('./service'),
  watchDeployment: require('./hubot/deploy_watcher'),
  watchStatus: require('./hubot/status_watcher'),
  ...require('./errors'),
};
