# Description:
#   Handles TextMaster deployments
#
# Commands:
#   hubot deploy <app> on <env> - Deploy <app> master branch on <env> cluster
#
# Author:
#   gottfrois

module.exports = (robot)->
  _ = require('underscore')
  semaphore = require('semaphore-api')(robot)

  # Not used yet
  # deploy_through_cloud66 = (msg, name, env)=>
  #   robot
  #     .http("https://app.cloud66.com/api/3/stacks.json")
  #     .header('Authorization', "Bearer #{process.env.HUBOT_CLOUD66_AUTH_TOKEN}")
  #     .get() (err, res, body)->
  #       payload = JSON.parse(body)
  #       stack = _.findWhere(payload["response"], name: name, environment: env)
  #       robot
  #         .http("https://app.cloud66.com/api/3/stacks/#{stack.uid}/deployments.json")
  #         .header('Authorization', "Bearer #{process.env.HUBOT_CLOUD66_AUTH_TOKEN}")
  #         .post({}) (err, res, body)->
  #           payload = JSON.parse(body)
  #           msg.reply payload["response"]["message"]

  deploy_through_semaphore = (msg, name, env)=>
    branch_name = 'master'
    env_regex   = new RegExp(".*#{env}.*", "i")

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
            msg.reply "Couldn't deploy #{branch_name} yet, will do as soon as spec passes."

  robot.respond /deploy (.*) (?:on|to) (.*)/, (msg)=>
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
      { alias: "client-app", name: "client_frontend", env: "production", func: deploy_through_semaphore },
    ]
    stack = _.findWhere(mapper, { alias: alias, env: env })

    if stack and _.isFunction(stack.func)
      stack.func(msg, stack.name, stack.env)
    else
      msg.reply "Eh?"
