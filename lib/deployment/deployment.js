const EventEmitter = require('events');
const _ = require('underscore');
const {BuildFailed, DeploymentFailed} = require('./errors');
const DeploymentTarget = require('./deployment_target');

class DeployCanceled extends Error{
}

class Deployment extends EventEmitter {
  constructor({buildManager}) {
    super();
    this.buildManager = buildManager;
  }

  async deploy({serviceName, branchName, serverName, force = false}) {
    this.serviceName = serviceName;
    this.branchName = branchName;
    this.serverName = serverName;
    this.force = force;

    try {
      this.inProgress = true;

      this.emit('start', this);

      await this._findDeploymentTarget();

      this.buildStatus = this.branch.result;
      this.emit('build-status', this);

      if(this.buildStatus === 'pending') {
        await this._waitForBuild();
      }
      await this._checkStatusAndDeploy();
      this._complete();
    } catch(e) {
      this._handleError(e);
    }
  }

  cancel() {
    if(this.deploying || this.deployResult) {
      return false;
    }
    this._canceling = true;
    if (this._waitPromise) {
      this._waitPromise.cancel();
    }
    this.emit('canceling', this);
    return true;
  }

  forceDeploy() {
    if(this.deployResult) {
      return false;
    }
    this.force = true;
    if (this._waitPromise) {
      this._waitPromise.cancel();
    } else if(!this.inProgress && this.buildStatus == 'failed') {
      this.inProgress = true;
      this._deploy().catch(e => this._handleError(e)).then(() => this._complete());
    }
    return true;
  }

  rebuild() {
    if(this.inProgress || this.deployResult || !this.buildFailed == 'failed') {
      return false;
    }
    this._rebuild().catch(e => this._handleError(e));
    return true;
  }

  _complete() {
    this.inProgress = false;
    this.emit('complete', this);
  }

  _handleError(e) {
    if(e.constructor === DeployCanceled) {
      this._canceled = true;
      this.inProgress = false;
      delete this._canceling;
      this.emit('canceled', this);
    } else {
      this.inProgress = false;
      this.emit('error', e, this);
    }
  }

  _checkForCancel() {
    if(this._canceling) {
      throw new DeployCanceled();
    }
  }

  async _rebuild() {
    this.inProgress = true;
    delete this.buildFailed;
    delete this.buildResult
    this.emit('rebuilding', this);

    await this.deployTarget.rebuild();

    await this._waitForBuild();
    await this._checkStatusAndDeploy();

    this._complete();
  }

  async _findDeploymentTarget() {
    this.deployTarget = new DeploymentTarget();
    for(const event of ['project', 'branch', 'server', 'commits']){
      this.deployTarget.on(event, () => {
        this[event] = this.deployTarget[event];
        this.emit(event, this);
      });
    }
    const {serviceName, branchName, serverName} = this;
    await this.deployTarget.fetch({serviceName, branchName, serverName});
  }

  async _waitForBuild() {
    this.emit('waiting', this);
    this._waitPromise = this.buildManager.waitForBranch({projectId: this.project.hash_id, branchName: this.branch.branch_name});
    try {
      let build = await this._waitPromise;
      this.buildStatus = build.result;
      this.emit('build-status', this);
      return build;
    } catch (e) {
      if(this._waitPromise.isCanceled) {
        if(this._canceling) {
          throw new DeployCanceled();
        }
        if (this.force) {
          this.emit('skip-tests', this);
          return;
        }
      }
      throw e;
    } finally {
      delete this._waitPromise;
    }
  }

  _checkStatusAndDeploy() {
    if (this.force) {
      this.emit('skip-tests', this);
    }
    if(this.force || this.buildStatus === 'passed') {
      return this._deploy();
    }else if (this.buildStatus === 'failed' || this.buildStatus === 'stopped') {
      this.buildFailed = true;
      throw new BuildFailed({branch: this.branch});
    }
    throw new Error(`Unknown build result ${this.buildStatus}`);
  }

  async _deploy() {
    this.deploying = true;
    this.deployResult = await this.deployTarget.deploy();
    this.emit('deploying', this);

    const deployNotification = await this.buildManager.waitForDeploy({
      projectId: this.project.hash_id,
      serverName: this.deployResult.server_name,
      deployNumber: this.deployResult.number
    });
    if(deployNotification.result !== 'passed') {
      throw new DeploymentFailed({deploy: deployNotification});
    }
    this.emit('deployed', this);

    this.deploying = false;
  }
}

module.exports = Deployment;
