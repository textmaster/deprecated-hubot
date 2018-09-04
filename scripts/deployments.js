// Description:
//   Allows services deployments through SemaphoreCI
//
// Commands:
//   hubot deploy <semaphore_project_name> <branch_name> on <server_name> - Deploy <semaphore_project_name> <branch_name> on <server_name> server.
//   hubot deploy <semaphore_project_name> on <server_name> - Deploy <semaphore_project_name> on <server_name> server using last deployed branch.
//   hubot force deploy <semaphore_project_name> <branch_name> on <server_name> - Deploy even if build failed, dont wait on specs
//   hubot skip tests - If build is waiting on tests, stop waiting and deploy immediately
//   hubot rebuild - Rebuild current deploy (if build is failing)
//   hubot cancel deploy - If deploy is waiting on tests, cancel deploy.

const LRU = require("lru-cache")
const {
  getDeploymentService,
  watchDeployment,
  watchStatus,
 } = require('../lib/deployment');

const getThreadId = msg => msg.message.metadata ? msg.message.metadata.thread_id : 'console';

module.exports = function(robot) {
  const deployments = getDeploymentService(robot);

  const deploymentThreads = LRU(50);

  robot.respond(/(force |ninja )?deploy (\S* )(\S* )?(?:on |to )(.*)$/, function(msg) {
    const threadId = getThreadId(msg);

    const force = !!msg.match[1]
    const serviceName = msg.match[2].trim();
    const branchName = msg.match[3] ? msg.match[3].trim() : null;
    const serverName = msg.match[4].trim();

    const deployment = deployments.deploy({serviceName, branchName, serverName, force});
    deploymentThreads.set(threadId, deployment);
    watchDeployment({deployment, msg});
  });

  robot.respond(/force deploy|skip tests/, function(msg) {
    const threadId = getThreadId(msg);
    const deployment = deploymentThreads.get(threadId);

    if (!deployment) {
      msg.send(`Can't find deployment in current thread`);
      return;
    }

    if(!deployment.forceDeploy()){
      msg.send(`Can't force deployment of ${deployment.serviceName} ${deployment.serverName} - deploy already started`);
    }
  });

  const rebuild = (msg, deployment) => {
    if(!deployment.rebuild()){
      msg.send(`Can't rebuild deployment of ${deployment.serviceName} ${deployment.serverName}`);
    }
  }

  robot.respond(/rebuild$/, function(msg) {
    const threadId = getThreadId(msg);
    const deployment = deploymentThreads.get(threadId);

    if (!deployment) {
      msg.send(`Can't find deployment in current thread`);
      return;
    }
    rebuild(msg, deployment);
  });

  const cancel = (msg, deployment) => {
    if(deployment.cancel()){
      msg.send(`Cancelling deployment of ${deployment.serviceName} ${deployment.serverName}`);
    } else {
      msg.send(`Can't cancel deployment of ${deployment.serviceName} ${deployment.serverName} - deploy already started`);
    }
  }

  robot.respond(/cancel deploy (\S* )?(?:on |to )(.*)?/, function(msg) {
    const serviceName = msg.match[1] ?  msg.match[1].trim() : null;
    const serverName = msg.match[2] ? msg.match[2].trim() : null;

    const deployment = deployments.find({serviceName, serverName});

    if (!deployment) {
      msg.send(`Can't find deployment for ${serviceName} ${serverName}`);
      return;
    }
    cancel(msg, deployment);
  });

  robot.respond(/cancel deploy/, function(msg) {
    const threadId = getThreadId(msg);
    const deployment = deploymentThreads.get(threadId);

    if (!deployment) {
      msg.send(`Can't find deployment in current thread`);
      return;
    }
    cancel(msg, deployment);
  });

  robot.respond(/list test server branches/, function(msg) {
    msg.send(`Command removed, try \`hubot list textmaster servers\` instead`);
  });

  robot.respond(/list (\S+) servers/, function(msg) {
    const serviceName = msg.match[1].trim();
    const status = deployments.getStatus({serviceName});

    watchStatus({status, msg});
  });

  // Debug
  robot.respond(/notifybuild (\S* )(\S* )(.*)/, function(msg) {
    const project_hash_id = msg.match[1].trim();
    const branch_name = msg.match[2].trim();
    const result = msg.match[3].trim();

    const build = {project_hash_id, branch_name, result};
    deployments.notifyBuild(build);
    msg.send("BuildManager notified");
  });

  robot.on('semaphore-build', function(build) {
    deployments.notifyBuild(build);
  });

  // Debug
  robot.respond(/notifydeploy (\S* )(\S* )(\d+) (passed|failed|stopped)/, function(msg) {
    const project_hash_id = msg.match[1].trim();
    const server_name = msg.match[2].trim();
    const number = Number(msg.match[3].trim());
    const result = msg.match[4];

    const deploy = {project_hash_id, server_name, number, result};
    deployments.notifyDeploy(deploy);
    msg.send("BuildManager notified");
  });

  robot.on('semaphore-deploy', function(deploy) {
    deployments.notifyDeploy(deploy);
  });

};
