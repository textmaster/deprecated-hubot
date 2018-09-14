const octokit = require('@octokit/rest')();

octokit.authenticate({
  type: 'token',
  token: process.env.HUBOT_GITHUB_TOKEN,
});

async function findPRForBranch({owner, repo, branch}) {
  const {data: prs} = await octokit.pullRequests.getAll({owner, repo});
  return prs.find(({head: {ref}}) => ref == branch);
}

const compareCommits = ({owner, repo, base, head}) =>
  octokit.repos.compareCommits({owner, repo, base, head})

const findCommit = opt => octokit.gitdata.getCommit(opt).then(({data}) => data);

const parseCommitUrl = (url) => {
  const re = new RegExp("//github.com/([^/]+)/([^/]+)/");
  const [_, owner, repo] = re.exec(url);
  return {owner, repo};
};

module.exports = {findPRForBranch, findCommit, compareCommits, parseCommitUrl};
