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
    user = msg.envelope.user
    room = msg.envelope.room
    thread_id = msg.message.metadata.thread_id

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
              robot.brain.set "queue-semaphore-deployment-deploy-#{project.hash_id}-#{build.commit.id}", {
                user: user,
                room: room,
                thread_id: thread_id
              }
              msg.reply "Deploying #{branch_name} on #{_.pluck(servers, 'name').join()}"
          else
            robot.brain.set "queue-semaphore-deployment-build-#{project.hash_id}-#{build.commit.id}", {
              branch_id: branch.id,
              branch_name: branch_name,
              env_regex: env_regex,
              user: user,
              room: room,
              thread_id: thread_id
            }
            msg.reply "Couldn't deploy #{branch_name} yet, will do as soon as spec passes."

  # { project_name: 'TextMaster.com',
  #   project_hash_id: '6550c0d1-a0f7-412e-951a-6524840a451b',
  #   server_name: '[sandbox] textmaster (Cloud66)',
  #   number: 992,
  #   event: 'deploy',
  #   result: 'passed',
  #   finished_at: '2018-03-06T09:59:20Z',
  #   created_at: '2018-03-06T09:40:40Z',
  #   updated_at: '2018-03-06T09:59:20Z',
  #   started_at: '2018-03-06T09:40:46Z',
  #   html_url: 'https://semaphoreci.com/textmaster/textmaster-com/servers/sandbox-textmaster-cloud66/deploys/992',
  #   branch_name: 'master',
  #   build_number: 6361,
  #   build_html_url: 'https://semaphoreci.com/textmaster/textmaster-com/branches/master/builds/6361',
  #   branch_html_url: 'https://semaphoreci.com/textmaster/textmaster-com/branches/master',
  #   commit: {
  #     id: '7465f5795a229678f00f2083b170ba758c881b07',
  #     url: 'https://github.com/textmaster/TextMaster.com/commit/7465f5795a229678f00f2083b170ba758c881b07',
  #     author_name: 'Maciek',
  #     author_email: 'maciejrzasa@gmail.com',
  #     message: 'Merge pull request #5466 from textmaster/mrzasa/graphical-file-changes\n\nChange Graphic files option behavior',
  #     timestamp: '2018-03-06T09:26:49Z'
  #   }
  # }
  robot.on 'semaphore-deploy', (deploy)->
    console.log "Deploy hook"
    console.log deploy
    queued = robot.brain.get("queue-semaphore-deployment-deploy-#{deploy.project_hash_id}-#{deploy.commit.id}")

    console.log "Queued"
    console.log queued

    if queued
      user = queued.user
      envelope = {
        user: user
        metadata: {
          room: queued.room,
          thread_id: queued.thread_id,
        }
      }

      if deploy.result is "pending"
        semaphore.builds(deploy.project_hash_id).info 'master', deploy.build_number, (response)->

          console.log "Build info"
          console.log response

          msg = "Successfuly deployed the following commits to #{deploy.server_name}:\n"
          _.map(response.commits, (commit)->
            msg += "* [#{commit.id.substring(0, 10)}](#{commit.url}) \"#{commit.message}\" from #{commit.author_name}\n"
          )
          robot.brain.set("queue-semaphore-deployment-deploy-#{deploy.project_hash_id}-#{deploy.commit.id}", null)
          robot.send envelope, msg
      else
        robot.send envelope, "@#{user.name}: Deployment failed #{deploy.html_url}"

  robot.on 'semaphore-build', (build)->
    if build.result is "passed"
      queued = robot.brain.get("queue-semaphore-deployment-build-#{build.project_hash_id}-#{build.commit.id}")
      user = queued.user
      envelope = {
        user: user
        metadata: {
          room: queued.room,
          thread_id: queued.thread_id,
        }
      }
      if queued
        semaphore.servers build.project_hash_id, (servers)->
          servers = _.select servers, (server)->
            server.name.match(queued.env_regex)
          _.each servers, (server)->
            semaphore.builds(build.project_hash_id).deploy queued.branch_id, build.build_number, server.id, (response)->
          robot.brain.set("queue-semaphore-deployment-build-#{build.project_hash_id}-#{build.commit.id}", null)
          robot.brain.set "queue-semaphore-deployment-deploy-#{build.project_hash_id}-#{build.commit.id}", {
            user: user,
            room: room,
            thread_id: thread_id
          }
          robot.send envelope, "@#{user.name}: #{queued.branch_name} build passed, now deploying on #{_.pluck(servers, 'name').join()}"

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
