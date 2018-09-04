const {
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
} = require('./messages');
const {
  BuildFailed,
  ProjectNotFound,
  ServerNotFound,
  BranchNotFound,
  BuildNotFound,
  DeploymentFailed,
} = require('../../errors');

function watchDeployment({deployment, msg}) {
  deployment.on('start', d => msg.send(startMessage(d)));
  deployment.on('build-status', d => msg.send(buildStatusMessage(d)));
  deployment.on('skip-tests', d => msg.send(skipTestMessage(d)));
  deployment.on('rebuilding', d => msg.send(rebuildingMessage(d)));
  deployment.on('waiting', d => msg.send(waitingMessage(d)));
  deployment.on('deploying', d => msg.send(`@${msg.envelope.user.name} ` + deployingMessage(d)));
  deployment.on('deployed', d => msg.send(`@${msg.envelope.user.name} ` + deployedMessage(d)));
  deployment.on('canceled', d => msg.send(cancelMessage(d)));

  deployment.on('error', (e, d) => {
    switch(e.constructor) {
      case BuildFailed:
        msg.send(buildFailedMessage(d, e));
        break
      case ProjectNotFound:
        msg.send(projectNotFoundMessage(d, e));
        break
      case BuildNotFound:
        msg.send(buildNotFoundMessage(d, e));
        break;
      case BranchNotFound:
        msg.send(branchNotFoundMessage(d, e));
        break;
      case ServerNotFound:
        msg.send(serverNotFoundMessage(d, e));
        break;
      case DeploymentFailed:
        msg.send(deploymentFailedMessage(d, e));
        break;
      default:
        msg.send(unknownErrorMessage(d, e));
        msg.send()
    }
  });
}

module.exports = watchDeployment;
