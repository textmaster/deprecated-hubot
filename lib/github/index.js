const octokit = require('@octokit/rest')()

octokit.authenticate({
  type: 'token',
  token: process.env.HUBOT_GITHUB_TOKEN,
})

async function findPRForBranch({owner, repo, branch}){
  const { data: prs } = await octokit.pullRequests.getAll({owner, repo})
  return prs.find(({head: {ref}}) => ref == branch)
}

const findCommit = (opt) => octokit.gitdata.getCommit(opt).then(({data}) => data);

module.exports = { findPRForBranch, findCommit }
