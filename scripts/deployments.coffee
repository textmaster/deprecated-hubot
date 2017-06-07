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
            robot.brain.set "queue-semaphore-deployment-build-#{project.hash_id}-#{build.commit.id}", {
              branch_id: branch.id,
              branch_name: branch_name,
              env_regex: env_regex,
            }
            msg.reply "Couldn't deploy #{branch_name} yet, will do as soon as spec passes."

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

  robot.on 'semaphore-build', (build)->
    if build.result is "passed"
      queued = robot.brain.get("queue-semaphore-deployment-build-#{build.project_hash_id}-#{build.commit.id}")
      if queued
        semaphore.servers build.project_hash_id, (servers)->
          servers = _.select servers, (server)->
            server.name.match(queued.env_regex)
          _.each servers, (server)->
            semaphore.builds(build.project_hash_id).deploy queued.branch_id, build.build_number, server.id, (response)->
          robot.brain.set("queue-semaphore-deployment-build-#{build.project_hash_id}-#{build.commit.id}", null)
          robot.messageRoom 'Main', "#{queued.branch_name} build passed, now deploying on #{_.pluck(servers, 'name').join()}"

  robot.respond /deploy (.*) on (.*)/, (msg)=>
    alias  = msg.match[1]
    env    = msg.match[2]
    mapper = [
      { alias: "textmaster", name: process.env.HUBOT_SEMAPHORE_DEFAULT_PROJECT, env: "production", func: deploy_through_semaphore },
      { alias: "textmaster", name: process.env.HUBOT_SEMAPHORE_DEFAULT_PROJECT, env: "staging", func: deploy_through_semaphore },
      { alias: "textmaster", name: process.env.HUBOT_SEMAPHORE_DEFAULT_PROJECT, env: "sandbox", func: deploy_through_semaphore },
      { alias: "hookshot", name: "hookshot_service", env: "production", func: deploy_through_semaphore },
      { alias: "hookshot", name: "hookshot_service", env: "staging", func: deploy_through_semaphore },
      { alias: "glossary", name: "glossary_service", env: "staging", func: deploy_through_semaphore },
      { alias: "glossary", name: "glossary_service", env: "production", func: deploy_through_semaphore },
      { alias: "payment-gateway", name: "payment_gateway_service", env: "staging", func: deploy_through_semaphore },
      { alias: "payment-gateway", name: "payment_gateway_service", env: "production", func: deploy_through_semaphore },
      { alias: "machine-translation", name: "machine_translation_service", env: "staging", func: deploy_through_semaphore },
      { alias: "machine-translation", name: "machine_translation_service", env: "production", func: deploy_through_semaphore },
      { alias: "translation-memory", name: "translation_memory_service", env: "staging", func: deploy_through_semaphore },
      { alias: "translation-memory", name: "translation_memory_service", env: "production", func: deploy_through_semaphore },
      { alias: "backend", name: "tm_backend-docker", env: "production", func: deploy_through_semaphore },
      { alias: "backend", name: "tm_backend-docker", env: "staging", func: deploy_through_semaphore },
      { alias: "option-presets", name: "option_presets_service", env: "production", func: deploy_through_semaphore },
      { alias: "author-bff", name: "author_bff", env: "staging", func: deploy_through_semaphore },
      { alias: "author-bff", name: "author_bff", env: "production", func: deploy_through_semaphore },
    ]
    stack = _.findWhere(mapper, { alias: alias, env: env })

    if stack and _.isFunction(stack.func)
      stack.func(msg, stack.name, stack.env)
    else
      msg.reply "Eh?"
