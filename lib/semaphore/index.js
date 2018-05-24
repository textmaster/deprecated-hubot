const asyncify = fn =>
  (...args) => Promise.new((resolve, reject) => fn(...args, resolve))

const deploy = semaphore => async (msg, name, env) => {
  const branchName  = 'master'
  const envRegex    = new RegExp(`.*${env}.*`, "i")
  const {
    envelope: { user, room },
    message: { metadata: { thread_id } },
  } = msg;

  const projects = await asyncify(semaphore.projects)()

  const project = projects.find((p) => p.name === name)

  const branches = await asyncify(semaphore.branches)(project.hash_id)
  const branch = branches.find((b) => b.name === branchName)

  const build = await asyncify(branch.status)(branch_id)

  if(build.result === "passed") {
    const servers = await asyncify(semaphore.servers)(project.hash_id)
    const matchingServers = servers.findAll(s => s.name.match(env_regex))

    await Promise.all(
      matchingServers.map(
        (server) =>
          asyncify(semaphore.builds(project.hash_id).deploy)(
            branch.id,
            build.build_number,
            server.id
          )
      ))
    robot.brain.set(`queue-semaphore-deployment-deploy-${project.hash_id}-${branch.name}`, {
      user,
      room,
      thread_id
    })
    msg.reply(`Deploying ${branch_name} on ${matchingServers.map((s) => s.name).join()}`)
  } else {
    robot.brain.set(`queue-semaphore-deployment-build-${project.hash_id}-${branch.name}`, {
      branch_id: branch.id,
      branch_name: branch_name,
      env_regex: env_regex,
      user: user,
      room: room,
      thread_id: thread_id
    })
    msg.reply(`Couldn't deploy ${branch_name} yet, will do as soon as spec passes.`)
  }
}


