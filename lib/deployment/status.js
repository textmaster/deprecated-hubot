const EventEmitter = require('events');
const _ = require('underscore');
const {
  fetchProjects,
  fetchServers,
  fetchServerStatus,
  fetchBuildUsingBuildUrl,
}= require('../semaphore');
const {findPRForBranch, parseCommitUrl} = require('../github');
const {ProjectNotFound} = require('./errors');

class Status extends EventEmitter {

  async fetch({serviceName}) {
    try {
      this.serviceName = serviceName;

      this.project = await this._findProject(this.serviceName);
      this.emit('project');

      this.servers = await fetchServers(this.project.hash_id);
      this.emit('servers');

      await this._fetchServerStatuses();

      this.emit('complete');
    } catch (e) {
      this.emit('error', e);
    }
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

  _fetchServerStatuses() {
    this.serverStatus = {};
    return Promise.all(this.servers.map((server) => this._fetchServerStatus(server)));
  }

  async _fetchServerStatus(server) {
    let status;
    try {
      status = await fetchServerStatus({projectId: this.project.hash_id, serverId: server.id});
    } catch (e) {
      this.serverStatus[server.id] = {status: {result: "unknown"}};
      this.emit('status');
      return;
    }
    this.serverStatus[server.id] = {status};
    this.emit('status');
    const build_url = status.build_url;

    if (build_url) {
      const build = await fetchBuildUsingBuildUrl(build_url);
      this.serverStatus[server.id].build = build;
      this.emit('build');
      const {owner, repo} = parseCommitUrl(build.commits[0].url);
      const branch = build.branch_name;
      const pr = await findPRForBranch({owner, repo, branch});
      this.serverStatus[server.id].pr = pr;
      this.emit('pr');
    }
  }
};

module.exports = Status;
