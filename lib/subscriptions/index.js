module.exports = robot => {
  const subs =
    robot.brain.data.subscriptions || (robot.brain.data.subscriptions = {});

  const getEvent = event => subs[event] || (subs[event] = {});
  const persist = () => {
    robot.brain.data.subscriptions = subs;
    robot.brain.save();
  };

  return {
    subscribe: (event, key, value) => {
      getEvent(event)[key] = value;
      persist();
    },
    unsubscribe: (event, key) => {
      const queue = getEvent(event);
      if (!queue[key]) return false;

      delete queue[key];
      persist();
      return true;
    },
    unsubscribeAllKeysFromEvent: event => {
      if (!subs[event]) return false;
      delete subs[event];
      persist();
      return true;
    },
    unsubscribeFromAllEvents: key => {
      let count = 0;
      for (const event in subs) {
        if (subs[event][key]) {
          delete subs[event][key];
          count += 1;
        }
      }
      if (count > 0) persist();

      return count;
    },
    subscribedEventsForKey: key => {
      const events = [];
      for (const event in subs) {
        if (subs[event][key]) {
          events.push(event);
        }
      }
      return events;
    },
  };
};
