class Subscriptions
  constructor: (robot)->
    @robot = robot
    @subs = robot.brain.data.subscriptions ||= {}

  subscriptions: (event)->
    if event
      @subs[event] ||= {}
      @subs[event]
    else
      @subs

  persist: (newSubscriptions)->
    @robot.brain.data.subscriptions = newSubscriptions
    @robot.brain.save()

  subscribe: (event, key, value)->
    @subscriptions(event)[key] = value
    @persist @subscriptions()

  unsubscribe: (event, key)->
    subs = @subscriptions()
    subs[event] ||= {}
    if subs[event][key]
      delete subs[event][key]
      @persist(subs)
      true
    else
      false

  unsubscribeAllKeysFromEvent: (event)->
    subs = @subscriptions()
    if event
      delete subs[event]
      @persist(subs)

  unsubscribeFromAllEvents: (key)->
    count = 0
    subs = @subscriptions()
    for event of subs
      if subs[event][key]
        delete subs[event][key]
        count += 1
    @persist(subs)

    return count

  subscribedEventsForKey: (key)->
    events = []
    subs = @subscriptions()

    for event of subs
      if subs[event][key]
        events.push(event)

    return events

module.exports = (robot)->
  new Subscriptions(robot)
