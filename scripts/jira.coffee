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
            .http(jiraUrl + "/rest/api/2/issue/#{issue}/transitions")
            .auth(auth)
            .get() (err, res, body) ->
              status = JSON.parse(body).transitions.filter (trans)->
                trans.name.toLowerCase() is 'completed'

              robot.messageRoom 'Main', "Changing the status of #{issue} to #{status[0].name}"
              robot
                .http(jiraUrl + "/rest/api/2/issue/#{issue}/transitions")
                .header("Content-Type", "application/json")
                .auth(auth)
                .post(JSON.stringify({
                  transition: status[0]
                })) (err, res, body) ->
                  robot.messageRoom 'Main', if res.statusCode == 204 then "Success!" else body
