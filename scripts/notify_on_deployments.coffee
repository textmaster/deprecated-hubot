# Description:
#   Notify flow and users on deployments
#
# Author:
#   gottfrois

module.exports = (robot)->
  _             = require('underscore')
  semaphore     = require('semaphore-api')(robot)
  Subscriptions = require('../lib/subscriptions')(robot)

  formatName = (name)->
    "@#{name}"

  notify = (events, msg)->
    names = []
    for event in events
      subs = Subscriptions.subscriptions(event)
      for name of subs
        names.push(name)

    msg += "\n"
    msg += (formatName name for name in _.uniq(names)).join(', ')
    robot.messageRoom 'Main', msg

  # would be awesome with async/await :(
  notifyCommitsFromPayload = (events, payload)->
    branch_name  = payload.branch_name
    hash_id      = payload.project_hash_id
    build_number = payload.build_number

    semaphore.builds(hash_id).info branch_name, build_number, (response)->
      msg = "Semaphore #{payload.result} to deployed the following commits on #{payload.server_name}:\n"
      _.map response.commits, (commit)->
        unless commit.message.includes("Merge pull request")
          msg += "* [#{commit.id.substring(0, 8)}](#{commit.url}) \"#{commit.message}\" by #{commit.author_name}\n"

      notify(events, msg)
      Subscriptions.unsubscribeAllKeysFromEvent("semaphore.#{payload.event}.#{payload.number}")

  robot.on 'semaphore-deploy', (payload)->
    # we only care about production deployments
    return unless payload.server_name is 'production'

    notifyCommitsFromPayload([
      "semaphore.#{payload.event}.#{payload.result}",
      "semaphore.#{payload.event}.#{payload.number}"
    ], payload)
