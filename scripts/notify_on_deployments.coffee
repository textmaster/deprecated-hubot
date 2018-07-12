# Description:
#   Notify flow and users on deployments
#
# Author:
#   gottfrois

module.exports = (robot)->
  _ = require('underscore')
  semaphore = require('semaphore-api')(robot)

  subscriptions = (event)->
    subs = robot.brain.data.subscriptions ||= {}
    if event
      subs[event] ||= {}
      subs[event]
    else
      subs

  formatName = (name)->
    "@#{name}"

  notify = (event, msg)->
    subs  = subscriptions(event)
    names = _.keys(subs)

    msg += "\n"
    msg += (formatName name for name in names).join(', ')
    robot.messageRoom 'Main', msg

  # would be awesome with async/await :(
  notifyCommitsFromPayload = (event, payload)->
    branch_name  = payload.branch_name
    hash_id      = payload.project_hash_id
    build_number = payload.build_number

    semaphore.builds(hash_id).info branch_name, build_number, (response)->
      console.log response
      msg = "Semaphore #{payload.result} to deployed the following commits on #{payload.server_name}:\n"
      _.map response.commits, (commit)->
        unless commit.message.includes("Merge pull request")
          msg += "* [#{commit.id.substring(0, 10)}](#{commit.url}) \"#{commit.message}\" by #{commit.author_name}\n"

      notify(event, msg)


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
  robot.on 'semaphore-deploy', (payload)->
    # return unless payload.branch_name is 'master'
    return unless payload.event is 'deploy'

    if payload.result is 'passed'
      event = 'semaphore.deploy.passed'
      notifyCommitsFromPayload(event, payload)

    if payload.result is 'failed'
      event = 'semaphore.deploy.failed'
      notifyCommitsFromPayload(event, payload)
