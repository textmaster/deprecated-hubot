# Description:
#   Build given branch on semaphore
#
# Commands:
#   hubot build <branch_name> - Build <branch_name> on semaphore
#
# Author:
#   gottfrois

module.exports = (robot)->
  _         = require('underscore')
  semaphore = require('semaphore-api')(robot)

  robot.respond /deploy (.*)/, (msg)=>
    branch_name = msg.match[1]
    project_name = process.env.HUBOT_SEMAPHORE_DEFAULT_PROJECT
    production_regex = new RegExp(".*production.*", "i")

    semaphore.projects (projects)->
      project = _.findWhere(projects, name: project_name)
      semaphore.branches project.hash_id, (branches)->
        branch = _.findWhere(branches, name: branch_name)
        semaphore.branches(project.hash_id).status branch.id, (build)->

          semaphore.servers project.hash_id, (servers)->
            servers = _.select servers, (server)->
              server.name.match(production_regex)

            _.each servers, (server)->
              semaphore.builds(project.hash_id).deploy branch.id, build.build_number, server.id, (response)->

            msg.reply "Deploying #{branch_name} on #{_.pluck(servers, 'name').join()}"



  robot.respond /build (.*)/, (msg)=>
    branch_name  = msg.match[1]
    project_name = process.env.HUBOT_SEMAPHORE_DEFAULT_PROJECT

    semaphore.projects (projects)->
      project = _.findWhere(projects, name: project_name)
      semaphore.branches project.hash_id, (branches)->
        branch = _.findWhere(branches, name: branch_name)
        semaphore.branches(project.hash_id).status branch.id, (build)->
          semaphore.builds(project.hash_id).rebuild branch.id, build.build_number, (response)->
            msg.reply "Here you go man (#{response.html_url})"
