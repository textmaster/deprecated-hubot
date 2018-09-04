const fetch = require('node-fetch');
const Semaphore = require('semaphore-api');
const promisify = require('../utils/promisify');

async function fetchBuildUsingBuildUrl(url) {
  const response = await fetch(url, {headers: {Accept: 'application/json'}});
  const json = await response.json();
  return json;
}

function fetchBuild(project_hash_id, branch_name, build_number) {
  return new Promise(function(resolve) {
    return Semaphore.builds(project_hash_id).info(
      branch_name,
      build_number,
      resolve,
    );
  });
}

function fetchDeployment(project_hash_id, server_name, deploy_number) {
  return new Promise(function(resolve) {
    return Semaphore.deploys(project_hash_id, server_name).info(
      deploy_number,
      resolve,
    );
  });
}

function buildHistory(project_hash_id, branch, opts) {
  return new Promise(function(resolve) {
    return Semaphore.branches(project_hash_id).history(branch, opts, resolve);
  });
}

const fetchProjects = () => promisify(Semaphore, 'projects')();

const fetchServers = (projectId) => promisify(Semaphore, 'servers')(projectId);

const fetchServerStatus = ({projectId, serverId}) =>
  promisify(Semaphore.servers(projectId), 'status')(serverId);

const deploy = ({projectId, branchName, buildNumber, serverName}) =>
  promisify(Semaphore.builds(projectId), 'deploy')(branchName, buildNumber, serverName);

const rebuild = ({projectId, branchName, buildNumber}) =>
  promisify(Semaphore.builds(projectId), 'rebuild')(branchName, buildNumber);


module.exports = {
  fetchProjects,
  fetchBuildUsingBuildUrl,
  fetchBuild,
  fetchProjects,
  fetchServers,
  fetchServerStatus,
  fetchDeployment,
  buildHistory,
  deploy,
  rebuild,
};
