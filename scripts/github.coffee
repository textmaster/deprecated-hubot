# Description:
#   Will mark Jira issues to In Review when a PR gets created for that Jira issue.
#
# Author:
#   gottfrois

module.exports = (robot)->
  _          = require('underscore')
  github     = require('githubot')(robot)
  issueRegex = new RegExp("(TM-[0-9]+).*$")
  jiraUrl    = process.env.HUBOT_JIRA_URL
  auth       = "#{process.env.HUBOT_JIRA_USERNAME}:#{process.env.HUBOT_JIRA_PASSWORD}"

  robot.on 'github-pull-requests', (data)->
    if process.env.HUBOT_JIRA_AUTO_REVIEW_ON_PR is '1'

      issueIds = []
      github.get data.pull_request.commits_url, (commits)->
        _.each commits, (commit)->
          m = commit.commit.message.match(issueRegex)
          if m
            issueIds.push(m[1])

        issueIds = _.uniq(issueIds)
        _.each issueIds, (issue)->

          robot
            .http(jiraUrl + "/rest/api/2/issue/#{issue}")
            .auth(auth)
            .get() (err, res, body)->
              fields = JSON.parse(body).fields
              status = fields.status

              statusName = status.name.toLowerCase()
              if statusName isnt 'in review' and statusName isnt 'completed' and statusName isnt 'closed' and statusName isnt 'ready for release'
                robot
                  .http(jiraUrl + "/rest/api/2/issue/#{issue}/transitions")
                  .auth(auth)
                  .get() (err, res, body)->
                    newStatus = JSON.parse(body).transitions.filter (trans)->
                      trans.name.toLowerCase() is 'in review'

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
