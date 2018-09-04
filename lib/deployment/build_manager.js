const EventEmitter = require('events');
const CancelablePromise = require('p-cancelable');

class BuildManager extends EventEmitter {
  notifyBuild(build) {
    const {project_hash_id: projectId, branch_name: branchName} = build;
    this.emit('build', {projectId, branchName, build});
  }

  notifyDeploy(deploy) {
    this.emit('deploy', deploy);
  }

  waitForBranch({projectId, branchName}) {
    return this._waitFor('build', build => build.projectId === projectId && build.branchName === branchName).then(({build}) => build);
  }

  waitForDeploy({projectId, serverName, deployNumber}) {
    console.log("Waiting for deploy", {projectId, serverName, deployNumber});
    return this._waitFor('deploy', deploy =>
                         deploy.number === deployNumber &&
                         deploy.project_hash_id === projectId &&
                         deploy.server_name === serverName
                        );
  }

  _waitFor(event, filter) {
    return new CancelablePromise((resolve, reject, onCancel) => {
      const listener = result => {
        if (filter(result)) {
          this.off(event, listener);
          resolve(result);
        }
      };
      onCancel(() => this.off(event, listener));
      this.on(event, listener);
    });
  }
}

module.exports = BuildManager;
