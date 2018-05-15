const fetch = require('node-fetch');

const ACCESS_TOKEN = process.env.C66_PERSONAL_ACCESS_TOKEN || process.env.HUBOT_CLOUD66_AUTH_TOKEN;

const STACK_ID = 'f2a96ed716b2880ae2b2c93e3a753215' // Test-5
const STACKS = [
  { name: 'Test-1', id: '3f72cb41019679473f551231802f3a90' },
  { name: 'Test-2', id: '9ff756181884630cfc6206415a5eca12' },
  { name: 'Test-3', id: 'ac7c43369aceb4a52d5cad94f7baf4bf' },
  { name: 'Test-4', id: '198f011723502480b94e8c0785ebe728' },
  { name: 'Test-5', id: 'f2a96ed716b2880ae2b2c93e3a753215' },
  { name: 'Test-6', id: '91ac6f4c0c27511d562d79a64d158071' },
]

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

async function getDeployBranch(stack_id) {
  const env = await fetchEnvronments(stack_id);
  return (env.find((e) => e.key == 'DEPLOY_BRANCH') || {}).value
}

module.exports = { listDeployBranches, getDeployBranch }
// listStacks();
