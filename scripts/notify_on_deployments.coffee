# Description:
#   Notify flow and users on deployments
#
# Author:
#   gottfrois

module.exports = (robot)->
  _             = require('underscore')
  semaphore     = require('semaphore-api')(robot)
  Subscriptions = require('../lib/subscriptions')(robot)
  Queues        = require('../lib/queues')(robot)

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
    message = "Semaphore #{payload.result} to deployed the following commits on #{payload.server_name}:\n"
    builds  = Queues.popAll("commits.#{payload.project_hash_id}")

    for build_number, commit in builds
      message += "* [#{commit.id.substring(0, 8)}](#{commit.url}) \"#{commit.message}\" by #{commit.author_name}\n"

    notify(events, message)
    Subscriptions.unsubscribeAllKeysFromEvent("semaphore.#{payload.event}.#{payload.number}")

  robot.on 'semaphore-deploy', (payload)->
    # we only care about production deployments
    return unless payload.server_name is 'production'

    notifyCommitsFromPayload([
      "semaphore.#{payload.event}.#{payload.result}",
      "semaphore.#{payload.event}.#{payload.number}"
    ], payload)
