# Description:
#   Deploy your current branch to server
#
# Commands:
#   hubot deploy my (*.) to <server> - Deploy your current branch to server
#
# Author:
#   gottfrois

module.exports = (robot)->
  github = require('githubot')(robot)
  _      = require('underscore')

  robot.respond /deploy my .* to (.*)/, (msg)=>
    server             = msg.match[1]
    project            = process.env.HUBOT_SEMAPHOREAPP_DEFAULT_PROJECT || 'proj'
    potential_branches = []
    user_regex         = new RegExp("#{msg.message.user.name}", 'i')

    msg.send msg.random([
      "Ok I got you bro!",
      "Hold on!",
      "Damn you are fast! Hold on",
      "Hey Everybody! Pants on, we have shit to deploy",
      "I got you covered",
      "Baby I got you",
      "You got it!",
      "SIR YES SIR!",
      "Roger! Roger!",
      "Nice!",
      "You're amazing man, really. Hold on",
      "Finally! Just a sec",
      "I'm so proud of you :) Give me a minute"
    ])

    github.get 'user/repos', (repos)->
      repo  = _.findWhere(repos, name: project)
      owner = repo.owner

      github.get "repos/#{owner.login}/#{repo.name}/branches", (branches)->
        _.delay ->
          potential_branches.sort (a, b)->
            new Date(b.commit.commit.committer.date) - new Date(a.commit.commit.committer.date)
          ready(robot, msg, potential_branches, server, project)
        , 1000

        _.each branches, (b)=>
          github.get "repos/#{owner.login}/#{repo.name}/branches/#{b.name}", (b)->
            potential_branches.push(b) if b.commit.commit.author.name.match(user_regex)

ready = (robot, msg, potential_branches, server_name, project_name)->
  semaphore = require('semaphore-api')(robot)
  _         = require('underscore')

  if potential_branches.length is 0
    return msg.send "You don't have any shit!"

  branch_name = potential_branches[0].name
  semaphore.projects (projects)->
    server_regex = new RegExp(".*#{server_name}.*", "i")
    project      = _.findWhere(projects, name: project_name)
    branch       = _.findWhere(project.branches, branch_name: branch_name)
    build_number = branch.build_number

    semaphore.branches project.hash_id, (branches)->
      semaphore.servers project.hash_id, (servers)->
        branch = _.findWhere(branches, name: branch_name)
        servers = _.select servers, (server)->
          server.name.match(server_regex)

        if servers.length is 0
          msg.send msg.random([
            "Either you can't spell or I'm just dumb",
            "Look bro, I can't find any server matching that name :(",
            "Dude, are you sure about that name?",
            "Haha \"#{server_name}\", yeah right ;)",
            "This is just wrong..."
          ])
        else
          if servers.length > 1
            msg.send msg.random([
              "Nah! I don't feel like it, there are just too many servers out there matching #{server_name}",
              "Looks like there are multiple servers matching #{server_name}",
              "Dude, I'm a fucking robot not a magician...",
              "Come on... you can do better than that :)",
              "Hum... I don't know what to do... there are just so many choices :(",
              "Stop beeing an asshole and do the things right! I'm done with this shit!"
            ])
          else
            server = servers[0]
            semaphore.builds(project.hash_id).deploy branch.id, build_number, server.id, (response)->

              interval = setInterval ->
                semaphore.deploys(project.hash_id, server.id).info response.number, (response)->
                  switch response.result
                    when 'passed'
                      clearInterval(interval)
                      msg.reply msg.random([
                        "I'm done with this shit (#{response.html_url})",
                        "Here you go man (#{response.html_url})",
                        "Hell yeah! (#{response.html_url})",
                        "Check this out (#{response.html_url})",
                        "Oh yeah! (#{response.html_url})",
                        "What about that? (#{response.html_url})",
                        "Boom! (#{response.html_url})",
                        "Done! (#{response.html_url})"
                      ])
                    when 'failed'
                      clearInterval(interval)
                      msg.reply msg.random([
                        "Oh Oh! Looks like something is wrong :( (#{response.html_url})",
                        "Oh man.. That's not good :( (#{response.html_url})",
                        "Hell no! (#{response.html_url})",
                        "and... fuck :( (#{response.html_url})",
                        "God damn it! (#{response.html_url})",
                        "Oh no :( (#{response.html_url})",
                        "Hum, I think it failed, you might want to check this out (#{response.html_url})"
                      ])
              , 10000
