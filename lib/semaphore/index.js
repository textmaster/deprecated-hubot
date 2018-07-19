const fetch = require('node-fetch');
const Semaphore = require('semaphore-api');

async function fetchBuildUsingBuildUrl(url) {
  const response = await fetch(url, { headers: { Accept: "application/json" } });
  const json = await response.json();
  return json;
}

async function fetchBuild(project_hash_id, branch_name, build_number) {
  return new Promise(function(resolve) {
    return Semaphore.builds(project_hash_id).info(branch_name, build_number, resolve);
  });
}

async function fetchDeployment(project_hash_id, server_name, deploy_number) {
  return new Promise(function(resolve) {
    return Semaphore.deploys(project_hash_id, server_name).info(deploy_number, resolve);
  });
}

async function buildHistory(project_hash_id, branch, opts) {
  return new Promise(function(resolve) {
    return Semaphore.branches(project_hash_id).history(branch, opts, resolve);
  });
}

module.exports = {
  fetchBuildUsingBuildUrl,
  fetchBuild,
  fetchDeployment,
  buildHistory
}
