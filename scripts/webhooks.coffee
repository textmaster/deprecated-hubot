# Description:
#   Listen for webhooks and broadcast them to hubot listeners.
#
# Author:
#   gottfrois

module.exports = (robot)->

  robot.router.post '/hubot/cloud66-events/deploy', (req, res)->
    data = if req.body.payload? then JSON.parse req.body.payload else req.body
    robot.emit 'cloud66-deploy', data
    res.send 'OK'

  robot.router.post '/hubot/cloud66-events/build', (req, res)->
    data = if req.body.payload? then JSON.parse req.body.payload else req.body
    robot.emit 'cloud66-build', data
    res.send 'OK'

  robot.router.post '/hubot/semaphore-events/deploy', (req, res)->
    data = if req.body.payload? then JSON.parse req.body.payload else req.body
    robot.emit 'semaphore-deploy', data
    res.send 'OK'

  robot.router.post '/hubot/semaphore-events/build', (req, res)->
    data = if req.body.payload? then JSON.parse req.body.payload else req.body
    robot.emit 'semaphore-build', data
    res.send 'OK'
