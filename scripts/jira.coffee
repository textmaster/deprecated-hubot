# Description:
#   Listen for semaphore deploys and change Jira issue statuses.
#
# Author:
#   gottfrois

module.exports = (robot)->
  _         = require('underscore')
  semaphore = require('semaphore-api')(robot)
  jiraUrl   = process.env.HUBOT_JIRA_URL
  auth      = "#{process.env.HUBOT_JIRA_USERNAME}:#{process.env.HUBOT_JIRA_PASSWORD}"

  robot.on 'jira-issue-updated', (data)->
    userNameMapper =
      "alexandre": "alex"
      "sergio": "sergio"
      "nikolai": "nikolai"
      "krzysztof": "kris"
      "pierre-louis": "pierre-louis"
      "gareth": "gareth"
      "luke": "luke"
    comment = data.comment

    if comment
      issue   = data.issue.key
      author  = comment.author
      regex   = /\[~([^\]]+)\]/g
      matches = undefined
      users   = []

      while (matches = regex.exec(comment.body))
        mappedUser = userNameMapper[matches[1]]
        if mappedUser
          users.push("@#{mappedUser}")

      if users.length > 0
        robot.messageRoom 'Main', "#{users.join(' ')}, #{author.displayName} commented on [#{issue}](https://textmaster.jira.com/browse/#{issue}).\n> #{comment.body}"



  robot.on 'semaphore-deploy', (data)->
    if process.env.HUBOT_JIRA_AUTO_COMPLETE_ON_DEPLOY is '1' and data.server_name is process.env.HUBOT_SEMAPHORE_DEFAULT_SERVER and data.result is 'passed'

      robot.messageRoom 'Main', "Semaphore successfully deployed #{data.branch_name} on #{data.server_name} (#{data.html_url})"
      semaphore.builds(data.project_hash_id).info data.branch_name, data.build_number, (response)->
        issueIds = []
        issueRegex = new RegExp("(TM-[0-9]+).*$")
        _.each response.commits, (commit)->
          m = commit.message.match(issueRegex)
          if m
            issueIds.push(m[1])

        issueIds = _.uniq(issueIds)
        _.each issueIds, (issue)->

          robot
            .http(jiraUrl + "/rest/api/2/issue/#{issue}")
            .auth(auth)
            .get() (err, res, body)->
              fields   = JSON.parse(body).fields
              creator  = fields.creator
              assignee = fields.assignee
              status   = fields.status

              statusName = status.name.toLowerCase()
              if statusName isnt 'completed' and statusName isnt 'closed'
                robot
                  .http(jiraUrl + "/rest/api/2/issue/#{issue}/transitions")
                  .auth(auth)
                  .get() (err, res, body)->
                    newStatus = JSON.parse(body).transitions.filter (trans)->
                      trans.name.toLowerCase() is 'completed'

                    robot
                      .http(jiraUrl + "/rest/api/2/issue/#{issue}/transitions")
                      .header("Content-Type", "application/json")
                      .auth(auth)
                      .post(JSON.stringify({
                        transition: newStatus[0]
                      })) (err, res, body)->
                        if res.statusCode == 204
                          robot.messageRoom 'Main', "Successfully changed the status of [#{issue}](https://textmaster.jira.com/browse/#{issue}) from #{status.name} to #{newStatus[0].name}"
                        else
                          robot.messageRoom 'Main', body

              if assignee.name isnt creator.name
                robot
                  .http(jiraUrl + "/rest/api/2/issue/#{issue}/assignee")
                  .header("Content-Type", "application/json")
                  .auth(auth)
                  .put(JSON.stringify({
                    name: creator.name
                  })) (err, res, body) ->
                    if res.statusCode == 204
                      robot.messageRoom 'Main', "Successfully changed the assignee of [#{issue}](https://textmaster.jira.com/browse/#{issue}) to #{creator.displayName}"
                    else
                      robot.messageRoom 'Main', body
