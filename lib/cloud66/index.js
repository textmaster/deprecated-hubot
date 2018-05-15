const fetch = require('node-fetch');

const ACCESS_TOKEN = process.env.C66_PERSONAL_ACCESS_TOKEN || process.env.HUBOT_CLOUD66_AUTH_TOKEN;

const STACKS = [ { name: 'test-2', id: 'feb44c30a7862357acd566c19795f6c8' },
  { name: 'test-6', id: '3ac2aa3398d8db0fca0a78e0000a423f' },
  { name: 'test-5', id: '77d515d20c7764f23b02611719b30f7c' },
  { name: 'test-3', id: 'cc6b6f959a3705ed32f3918d896849b0' },
  { name: 'test-1', id: '6ff3c2a0e4cf7a3b3851a14d1e0cefdd' },
  { name: 'test-4', id: '9f05b7e562402b1c5b3a7c3f46c44215' } ]

async function listStacks() {
  const response = await fetch("https://app.cloud66.com/api/3/stacks.json", {headers: { Authorization: `Bearer ${ACCESS_TOKEN}` }})
  const json = await response.json();
  for(const stack of json.response) {
    console.log(`{ name: '${stack.name}', id: '${stack.uid}' },`);
  }
  return json;
}

async function fetchEnvronments(stack_id) {
  const response = await fetch(`https://app.cloud66.com/api/3/stacks/${stack_id}/environments.json`, {headers: { Authorization: `Bearer ${ACCESS_TOKEN}` }})
  const json = await response.json();
  // console.log("Environments", json)
  return json.response;
}

async function listDeployBranches() {
  let response = "";
  for (const {name, id} of STACKS) {
    const env = await fetchEnvronments(id);
    const branch = (env.find((e) => e.key == 'DEPLOY_BRANCH') || {}).value
    response += `${name} \t ${branch}`
  }
  return response;
}

async function fetchDeployments(stack_id) {
  const response = await fetch(`https://app.cloud66.com/api/3/stacks/${stack_id}/deployments.json`, {headers: { Authorization: `Bearer ${ACCESS_TOKEN}` }})
  const json = await response.json();
  // console.log("Environments", json)
  return json.response;
}

async function getLatestDeploy(stack_id) {
  const deployments = await fetchDeployments(stack_id);
  return deployments.find(d => d.git_hash)
}

async function getDeployBranch(stack_id) {
  const env = await fetchEnvronments(stack_id);
  return (env.find((e) => e.key == 'DEPLOY_BRANCH') || {}).value
}

module.exports = { listDeployBranches, getDeployBranch, fetchDeployments, getLatestDeploy, STACKS }
// listStacks();
