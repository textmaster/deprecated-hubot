# Description:
#   Handles TextMaster deployments
#
# Commands:
#   hubot deploy textmaster on production - Deploy TextMaster.com app master branch on all production servers
#   hubot deploy textmaster on staging - Deploy TextMaster.com app master branch on all staging servers
#   hubot deploy hookshot on production - Deploy Hookshot service on production server
#   hubot deploy hookshot on staging - Deploy Hookshot service on staging server
#   hubot deploy backend on production - Deploy Backend service on production server
#   hubot deploy backend on staging - Deploy Backend service on staging server
#   hubot deploy wms on production - Deploy WebscrapMaster service on production server
#
# Author:
#   gottfrois

module.exports = (robot)->
  _             = require('underscore')
  semaphore     = require('semaphore-api')(robot)
  Subscriptions = require('../lib/subscriptions')(robot)
  Queues        = require('../lib/queues')(robot)

  track = (deployment)->
    robot.brain.data.deployment = deployment
    robot.brain.save()

  deploy = (project_hash_id, branch_name, build_number, server_name, envelope)->
    semaphore.servers project_hash_id, (servers)->
      server = _.findWhere(servers, { name: server_name })

      if server
        semaphore.builds(project_hash_id).deploy branch_name, build_number, server.id, (response)->
          track(
            project_hash_id: project_hash_id,
            server_name:     server_name,
            number:          response.number,
          )

          Subscriptions.subscribe("semaphore.deploy.#{response.number}", envelope.user.name, envelope)

          robot.send envelope, "@#{envelope.user.name} Deploying #{branch_name} on #{server.name}"
      else
        message = "Cannot find server #{server_name}. Available servers are:\n"
        _.chain(servers)
         .sortBy (server)->
           server.name
         .each (server)->
           message += "* #{server.name}\n"

        robot.send envelope, message


  deploy_through_semaphore = (msg, project, server_name, branch_name)->
    branch = _.findWhere(project.branches, branch_name: branch_name)

    if branch
      if branch.result is 'passed'
        deploy(project.hash_id, branch.branch_name, branch.build_number, server_name, msg.envelope)

      if branch.result is 'pending'
        Queues.push(project.hash_id, branch.branch_name, { server_name: server_name, envelope: msg.envelope })
        msg.send "Scheduling deployment of branch [#{branch.branch_name}](#{branch.build_url}) as soon as build has passed."

      if branch.result is 'failed'
        Queues.push(project.hash_id, branch.branch_name, { server_name: server_name, envelope: msg.envelope })
        msg.send "Cannot deploy branch [#{branch.branch_name}](#{branch.build_url}) because build has failed."
          semaphore.rebuild branch.branch_name, branch.build_number, (build)->
            msg.send "Rebuilding [#{build.branch_name}](#{build.html_url}) and scheduling deployment as soon as build has passed."
    else
      message = "Cannot find branch #{branch_name} in #{project.name}'s branches. Available branches are:\n"
      _.chain(project.branches)
       .sortBy (branch)->
         branch.branch_name
       .each (branch)->
         message += "* [#{branch.result}] #{branch.branch_name}\n"
      msg.send message


  robot.on 'semaphore-build', (build)->
    queued = Queues.pop(build.project_hash_id, build.branch_name)

    if queued
      deploy(build.project_hash_id, build.branch_name, build.build_number, queued.server_name, queued.envelope)

  robot.respond /stop deploy|deployment/, (msg)->
    deployment = robot.brain.data.deployment || {}

    if deployment.server_name
      semaphore.stop deployment.project_hash_id, deployment.server_name, deployment.number, (response)->
        msg.send "Stopped #{response.project_name} deployment on #{response.server_name}."
    else
      msg.send "No deployment to stop."

  robot.respond /deploy (.*) (?:on|to) (.*)/, (msg)->
    service_name = msg.match[1].trim()
    server_name  = msg.match[2].trim()
    branch_name  = 'master'

    msg.send "Looking for #{service_name} #{branch_name}'s build status..."

    semaphore.projects (projects)->
      project = _.findWhere(projects, name: service_name)
      if project
        deploy_through_semaphore(msg, project, server_name, branch_name)
      else
        message = "Cannot find matching service with #{service_name}. Available services are:\n"

        _.chain(projects)
         .sortBy (project)->
           project.name
         .each (project)->
          master_branch = _.findWhere(project.branches, branch_name: 'master')
          if master_branch
            message += "* [#{master_branch.result}] #{project.name}\n"
          else
            message += "* [#{project.branches[0].result}] #{project.name}\n"

        msg.send(message)
