
class ProjectNotFound extends Error {
  constructor({name, projects}) {
    super(`Project '${name}' not found`);
    this.projectName = name;
    this.projects = projects;
  }
}

class ServerNotFound extends Error {
  constructor({name, servers}) {
    super(`Server '${name}' not found`);
    this.serverName = name;
    this.servers = servers;
  }
}

class BranchNotFound extends Error {
  constructor({name, branches}) {
    super(`Branch '${name}' not found`);
    this.branchName = name;
    this.branches = branches;
  }
}
class BuildNotFound extends Error {
  constructor({status}) {
    super(`Build not found for '${status.branch_name}' not found`);
    this.status = status;
  }
}

class BuildFailed extends Error {
  constructor({branch}) {
    super(`Build '${branch.branch_name}' failed`);
    this.branch = branch;
  }
}
class DeploymentFailed extends Error {
  constructor({deploy}) {
    super(`Deploy ${deploy.project_name} ${deploy.server_name} ${deploy.number} failed`);
    this.deploy = deploy;
  }
}

module.exports = {
  ProjectNotFound,
  ServerNotFound,
  BranchNotFound,
  BuildFailed,
  BuildNotFound,
  DeploymentFailed,
};
