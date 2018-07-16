module.exports = robot => {
  const qs = robot.brain.data.queues || (robot.brain.data.queues = {});

  const getEvent = (event) => (qs[event] || (qs[event] = {}));
  const persist = () => {
    robot.brain.data.queues = qs;
    robot.brain.save();
  };

  return {
    push(event, key, value){
      getEvent(event)[key] = value;
      persist();
    },
    pop(event, key) {
      const queue = getEvent(event)
      const value = queue[key];
      delete queue[key];
      if(value) persist();
      return value;
    }
  }
}
