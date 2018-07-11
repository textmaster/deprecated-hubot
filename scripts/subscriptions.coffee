# Description:
#   Subscribes current user to various event notifications.
#
# Commands:
#   hubot subscribe <event> - subscribes current user to event
#   hubot unsubscribe <event> - unsubscribes current user from event
#   hubot unsubscribe all events - unsubscribes current user from all events
#   hubot my subscriptions - show subscriptions of current user
#
# Author:
#   gottfrois

module.exports = (robot)->

  subscriptions = (event)->
    subs = robot.brain.data.subscriptions ||= {}
    if event
      subs[event] ||= {}
      subs[event]
    else
      subs

  persist = (subscriptions)->
    robot.brain.data.subscriptions = subscriptions
    robot.brain.save()

  robot.respond /subscribe ([a-z0-9\-\.\:_]+)$/i, (msg)->
    event    = msg.match[1]
    envelope = msg.envelope
    name     = envelope.user.name

    subscriptions(event)[name] = envelope
    persist subscriptions()
    msg.reply "Subscribed #{name} to #{event} event"

  robot.respond /unsubscribe ([a-z0-9\-\.\:_]+)$/i, (msg)->
    event    = msg.match[1]
    envelope = msg.envelope
    name     = envelope.user.name

    subs = subscriptions()
    subs[event] ||= {}
    if subs[event][name]
      delete subs[event][name]
      persist(subs)
      msg.reply "Unsubscribed #{name} from #{event} event"
    else
      msg.reply "#{name} was not subscribed to #{event} event"

  robot.respond /unsubscribe all events$/i, (msg)->
    count = 0
    subs = subscriptions()
    name = msg.envelope.user.name
    for event of subs
      if subs[event][name]
        delete subs[event][name]
        count += 1
    persist(subs)
    msg.reply "Unsubscribed #{name} from #{count} events"

  robot.respond /my subscriptions$/i, (msg)->
    message = ''
    count   = 0
    subs    = subscriptions()
    name    = msg.envelope.user.name
    for event of subs
      if subs[event][name]
        count += 1
        message += "#{event}\n"
    message += "Total subscriptions for #{name}: #{count}"
    msg.reply message
