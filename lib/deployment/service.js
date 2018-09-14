/* Deployment service
 *
 * Singleton service to manage deployment process
 */
const BuildManager = require('./build_manager');
const Deployment = require('./deployment');
const Status = require('./status');

let instance;

const Service = robot => {
  const buildManager = new BuildManager();
  const deployments = {};

  return {
    deploy: args => {
      const deployment = new Deployment({buildManager});
      const {serverName, serviceName} = args;
      deployments[serviceName] = deployments[serviceName] || [];
      deployments[serviceName][serverName] = deployment;

      setImmediate(() => deployment.deploy(args));

      return deployment;
    },
    notifyBuild: build => buildManager.notifyBuild(build),
    notifyDeploy: deploy => buildManager.notifyDeploy(deploy),
    find: ({serviceName, serverName}) => {
      if(deployments[serviceName]) {
        return deployments[serviceName][serverName];
      }
    },
    getStatus: ({serviceName}) => {
       const status = new Status();
       setImmediate(() => status.fetch({serviceName}));

       return status;
    },
  }
};

module.exports = robot => (instance = instance || Service(robot));
