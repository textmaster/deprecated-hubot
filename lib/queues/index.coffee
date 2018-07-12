class Queues
  constructor: (robot)->
    @robot = robot
    @qs = robot.brain.data.queues ||= {}

  queues: (event)->
    if event
      @qs[event] ||= {}
      @qs[event]
    else
      @qs

  persist: (newQueues)->
    @robot.brain.data.queues = newQueues
    @robot.brain.save()

  push: (event, key, value)->
    @queues(event)[key] = value
    @persist @queues()

  pop: (event, key)->
    qs = @queues()
    qs[event] ||= {}
    value = qs[event][key]

    if value
      delete qs[event][key]
      @persist(qs)

    return value

module.exports = (robot)->
  new Queues(robot)
