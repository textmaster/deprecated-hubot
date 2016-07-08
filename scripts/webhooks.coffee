# Description:
#   Listen for webhooks and broadcast them to hubot listeners.
#
# Author:
#   gottfrois

module.exports = (robot)->

  robot.router.post '/hubot/semaphore-events/deploy', (req, res)->
    data = if req.body.payload? then JSON.parse req.body.payload else req.body
    robot.emit 'semaphore-deploy', data
    res.send 'OK'

  robot.router.post '/hubot/github-events/pull-requests', (req, res)->
    data = if req.body.payload? then JSON.parse req.body.payload else req.body
    robot.emit 'github-pull-requests', data
    res.send 'OK'

  robot.router.post '/hubot/jira/issue-updated', (req, res)->
    data = if req.body.payload? then JSON.parse req.body.payload else req.body
    robot.emit 'jira-issue-updated', data
    res.send 'OK'

  robot.router.post '/hubot/backend-events/stats', (req, res)->
    data = if req.body.payload? then JSON.parse req.body.payload else req.body
    robot.emit 'backend-events-stats', data
    res.send 'OK'
