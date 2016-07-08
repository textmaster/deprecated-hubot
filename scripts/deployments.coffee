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
  _ = require('underscore')
  semaphore = require('semaphore-api')(robot)

  deploy_through_semaphore = (msg, name, env)=>
    branch_name  = 'master'
    env_regex    = new RegExp(".*#{env}.*", "i")

    semaphore.projects (projects)->
      project = _.findWhere(projects, name: name)
      semaphore.branches project.hash_id, (branches)->
        branch = _.findWhere(branches, name: branch_name)
        semaphore.branches(project.hash_id).status branch.id, (build)->
          if build.result is "passed"
            semaphore.servers project.hash_id, (servers)->
              servers = _.select servers, (server)->
                server.name.match(env_regex)
              _.each servers, (server)->
                semaphore.builds(project.hash_id).deploy branch.id, build.build_number, server.id, (response)->
              msg.reply "Deploying #{branch_name} on #{_.pluck(servers, 'name').join()}"
          else
            msg.reply "Can't deploy. Latest #{branch_name} build did not pass. (#{build.build_url})"

  deploy_through_cloud66 = (msg, name, env)=>
    robot
      .http("https://app.cloud66.com/api/3/stacks.json")
      .header('Authorization', "Bearer #{process.env.HUBOT_CLOUD66_AUTH_TOKEN}")
      .get() (err, res, body)->
        payload = JSON.parse(body)
        stack = _.findWhere(payload["response"], name: name, environment: env)
        robot
          .http("https://app.cloud66.com/api/3/stacks/#{stack.uid}/deployments.json")
          .header('Authorization', "Bearer #{process.env.HUBOT_CLOUD66_AUTH_TOKEN}")
          .post({}) (err, res, body)->
            payload = JSON.parse(body)
            msg.reply payload["response"]["message"]

  robot.respond /deploy (.*) on (.*)/, (msg)=>
    alias  = msg.match[1]
    env    = msg.match[2]
    mapper = [
      { alias: "textmaster", name: process.env.HUBOT_SEMAPHORE_DEFAULT_PROJECT, env: "production", func: deploy_through_semaphore },
      { alias: "textmaster", name: process.env.HUBOT_SEMAPHORE_DEFAULT_PROJECT, env: "staging", func: deploy_through_semaphore },
      { alias: "hookshot", name: "Hookshot", env: "production", func: deploy_through_cloud66 },
      { alias: "hookshot", name: "Hookshot", env: "staging", func: deploy_through_cloud66 },
      { alias: "backend", name: "TM Backend", env: "production", func: deploy_through_cloud66 },
      { alias: "backend", name: "TM Backend", env: "staging", func: deploy_through_cloud66 },
      { alias: "wms", name: "WMS Azure", env: "production", func: deploy_through_cloud66 },
    ]
    stack = _.findWhere(mapper, { alias: alias, env: env })

    if stack and _.isFunction(stack.func)
      stack.func(msg, stack.name, stack.env)
    else
      msg.reply "Eh?"
