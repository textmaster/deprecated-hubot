const EventEmitter = require('events');
const _ = require('underscore');
const {
  fetchProjects,
  fetchServers,
  fetchServerStatus,
  fetchBuildUsingBuildUrl,
  deploy,
  rebuild
}= require('../semaphore');
const {
  compareCommits,
  parseCommitUrl,
} = require('../github');
const {ProjectNotFound, BuildNotFound, BranchNotFound, ServerNotFound} = require('./errors');

class DeploymentTarget extends EventEmitter {

  async fetch({serviceName, branchName, serverName, force = false}) {
    this.serviceName = serviceName;
    this.branchName = branchName;
    this.serverName = serverName;

    this.project = await this._findProject(serviceName);
    this.emit('project', this);

    this.server = await this._findServer(serverName);
    this.emit('server', this);

    if (branchName && branchName.length > 0) {
      this.branch = await this._findBranch(branchName);
      await this._findLastDeployedBranch();
    } else {
      this.branch = await this._findLastDeployedBranch();
      if(!this.branch) {
        throw new BuildNotFound({status: this.serverStatus});
      }
      this.branchName = this.branch.branch_name;
    }
    this.emit('branch', this);

    this.commits = await this._compareCommits();
    this.emit('commits', this);
  }

  deploy() {
    return deploy({
      projectId: this.project.hash_id,
      branchName: this.branch.branch_name,
      buildNumber: this.branch.build_number,
      serverName: this.server.name,
    });
  }

  rebuild() {
    return rebuild({
      projectId: this.project.hash_id,
      branchName: this.branch.branch_name,
      buildNumber: this.branch.build_number,
    });
  }

  async _findProject(name) {
    const projects = await fetchProjects();
    const project = _.findWhere(projects, {name});
    if (!project) {
      const error = new ProjectNotFound({name, projects});
      throw error;
    }
    return project;
  }

  async _findServer(name) {
    const servers = await fetchServers(this.project.hash_id)
    const server = _.findWhere(servers, {name});
    if (!server) {
      const error = new ServerNotFound({name, servers});
      throw error;
    }
    return server;
  }

  async _findBranch(name) {
    const {branches} = this.project;
    const branch = _.findWhere(branches, {branch_name: name});
    if (!branch) {
      const error = new BranchNotFound({name, branches});
      throw error;
    }
    return branch;
  }

  async _findLastDeployedBranch() {
    this.serverStatus = await fetchServerStatus({projectId: this.project.hash_id, serverId: this.server.id});
    const buildUrl = this.serverStatus.build_url;
    if (!buildUrl) {
      return;
    }
    const build = this.previousBuild = await fetchBuildUsingBuildUrl(buildUrl);
    const branch = await this._findBranch(build.branch_name);

    return branch;
  }

  async _compareCommits() {
    const {owner, repo} = parseCommitUrl(this.serverStatus.commit.url);
    const base = this.serverStatus.commit.id;
    const head = this.branch.commit.id;

    const {data} = await compareCommits({owner, repo, base, head});
    return data;
  }
}

module.exports = DeploymentTarget;
