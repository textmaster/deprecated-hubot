// Description:
//   Allows services deployments through SemaphoreCI
//
// Commands:
//   hubot deploy <semaphore_project_name> on <server_name> - Deploy <semaphore_project_name> master branch on <server_name> server.
//
// Author:
//   gottfrois

module.exports = function (robot) {
  let _             = require('underscore');
  let semaphore     = require('semaphore-api')(robot);
  let Subscriptions = require('../lib/subscriptions')(robot);
  let Queues        = require('../lib/queues')(robot);

  let deploy = (project_hash_id, branch_name, build_number, server_name, envelope)=>
    semaphore.servers(project_hash_id, function(servers){
      let server = _.findWhere(servers, { name: server_name });

      if (server) {
        return semaphore.builds(project_hash_id).deploy(branch_name, build_number, server.id, function(response){
          Subscriptions.subscribe(`semaphore.deploy.${response.number}`, envelope.user.name, envelope);

          return robot.send(envelope, `@${envelope.user.name} Deploying ${branch_name} on ${server.name}`);
        });
      } else {
        let message = `Cannot find server ${server_name}. Available servers are:\n`;
        _.chain(servers)
         .sortBy(server=> server.name)
         .each(server=> message += `* ${server.name}\n`);

        return robot.send(envelope, message);
      }
    })
  ;

  let deploy_through_semaphore = function(msg, project, server_name, branch_name){
    let branch = _.findWhere(project.branches, {branch_name});

    if (branch) {
      if (branch.result === 'passed') {
        deploy(project.hash_id, branch.branch_name, branch.build_number, server_name, msg.envelope);
      }

      if (branch.result === 'pending') {
        Queues.push(project.hash_id, branch.branch_name, { server_name, envelope: msg.envelope });
        msg.send(`Scheduling deployment of branch [${branch.branch_name}](${branch.build_url}) as soon as build has passed.`);
      }

      if (branch.result === 'failed') {
        Queues.push(project.hash_id, branch.branch_name, { server_name, envelope: msg.envelope });
        msg.send(`Cannot deploy branch [${branch.branch_name}](${branch.build_url}) because build has failed.`);
        return semaphore.builds(project.hash_id).rebuild(branch.branch_name, branch.build_number, build=> msg.send(`Rebuilding [${build.branch_name}](${build.html_url}) and scheduling deployment as soon as build has passed.`));
      }
    } else {
      let message = `Cannot find branch ${branch_name} in ${project.name}'s branches. Available branches are:\n`;
      _.chain(project.branches)
       .sortBy(branch=> branch.branch_name)
       .each(branch=> message += `* [${branch.result}] ${branch.branch_name}\n`);
      return msg.send(message);
    }
  };

  robot.on('semaphore-build', function(build){
    let queued = Queues.pop(build.project_hash_id, build.branch_name);

    if (queued) {
      return deploy(build.project_hash_id, build.branch_name, build.build_number, queued.server_name, queued.envelope);
    }
  });

  return robot.respond(/deploy (.*) (?:on|to) (.*)/, function(msg){
    let service_name = msg.match[1].trim();
    let server_name  = msg.match[2].trim();
    let branch_name  = 'master';

    msg.send(`Looking for ${service_name} ${branch_name}'s build status...`);

    return semaphore.projects(function(projects){
      let project = _.findWhere(projects, {name: service_name});
      if (project) {
        return deploy_through_semaphore(msg, project, server_name, branch_name);
      } else {
        let message = `Cannot find matching service with ${service_name}. Available services are:\n`;

        _.chain(projects)
         .sortBy(project=> project.name)
         .each(function(project){
          let master_branch = _.findWhere(project.branches, {branch_name: 'master'});
          if (master_branch) {
            return message += `* [${master_branch.result}] ${project.name}\n`;
          } else {
            return message += `* [${project.branches[0].result}] ${project.name}\n`;
          }
        });

        return msg.send(message);
      }
    });
  });
};
