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
  Subscriptions = require('../lib/subscriptions')(robot)

  robot.respond /subscribe ([a-z0-9\-\.\:_]+)$/i, (msg)->
    event = msg.match[1]
    value = msg.envelope
    key   = msg.envelope.user.name

    Subscriptions.subscribe(event, key, value)

    msg.send "Subscribed #{key} to #{event} event"

  robot.respond /unsubscribe ([a-z0-9\-\.\:_]+)$/i, (msg)->
    event = msg.match[1]
    value = msg.envelope
    key   = msg.envelope.user.name

    if Subscriptions.unsubscribe(event, key)
      msg.send "Unsubscribed #{key} from #{event} event"
    else
      msg.send "#{key} was not subscribed to #{event} event"

  robot.respond /unsubscribe all keys from event ([a-z0-9\-\.\:_]+)$/i, (msg)->
    event = msg.match[1]

    Subscriptions.unsubscribeAllKeysFromEvent(event)

    msg.send "Unsubscribed all keys from event #{event}"

  robot.respond /unsubscribe all events$/i, (msg)->
    key = msg.envelope.user.name
    count = Subscriptions.unsubscribeFromAllEvents(key)

    msg.send "Unsubscribed #{key} from #{count} events"

  robot.respond /my subscriptions$/i, (msg)->
    message = ''
    key     = msg.envelope.user.name
    events  = Subscriptions.subscribedEventsForKey(key)

    for event in events
      message += "* #{event}\n"
    msg.send message
