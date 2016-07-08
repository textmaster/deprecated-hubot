# Description:
#   Handles Semaphore and Hubot integration
#
# Commands:
#   hubot build <branch_name> - Build <branch_name> on semaphore
#   hubot deploy production - Deploy master on all production servers
#
# Author:
#   gottfrois

module.exports = (robot)->
  _ = require('underscore')

  robot.on 'backend-events-stats', (data)->
    robot.messageRoom 'Main', "Here is the response from the backend service regarding your file:"
    robot.messageRoom 'Main', data

  processFileFromFlow = (msg)=>
    robot
      .http("https://#{process.env.HUBOT_FLOWDOCK_API_TOKEN}@api.flowdock.com/flows/textmaster/main/messages?event=file&limit=3")
      .get() (err, res, body)->
        payload = JSON.parse(body)
        file = _.findWhere(payload, event: 'file')

        if file
          msg.reply "Got it! Hold on"
          robot
            .http("https://#{process.env.HUBOT_FLOWDOCK_API_TOKEN}@api.flowdock.com/#{file.content.path}")
            .get() (err, res, body)->
              url = res.headers.location
              if url
                data =
                  callback_url: "https://hubot-textmaster.herokuapp.com/hubot/backend-events/stats"
                  version: 3
                  documents: [
                    remote_url: url
                    text_to_html: false
                  ]
                robot
                  .http("#{process.env.HUBOT_TM_BACKEND_URL}/documents/bulk_stats")
                  .post(JSON.stringify(data)) (err, res, body)->
                    msg.reply "Cool, backend service responded with #{res.statusCode}. Let's wait for it to process your file bro."
                    return true
              else
                msg.reply "Meh? Something went wrong when trying to retreive that file from flowdock. Sorry bro :("
                return false
        else
          msg.reply "Meh? Gonna wait a couple more seconds and retry :-/"
          return false

  robot.respond /give me backend stats for this file/, (msg)=>
    msg.reply "Sure, waiting for your file..."
    interval = setInterval ->
      clearInterval(interval) if processFileFromFlow(msg)
    , 2000
