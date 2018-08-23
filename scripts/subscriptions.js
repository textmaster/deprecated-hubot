// Description:
//   Subscribes current user to various event notifications.
//
// Commands:
//   hubot subscribe <event> - subscribes current user to event
//   hubot unsubscribe <event> - unsubscribes current user from event
//   hubot unsubscribe all events - unsubscribes current user from all events
//   hubot my subscriptions - show subscriptions of current user
//
// Author:
//   gottfrois

module.exports = function(robot) {
  const subscriptions = require('../lib/subscriptions')(robot);

  robot.respond(
    /subscribe ([a-z0-9\-\.\:_]+)$/i,
    ({match: [_, event], envelope: value}) => {
      const {
        user: {name: key},
      } = value;
      subscriptions.subscribe(event, key, value);
      msg.send(`Subscribed ${key} to ${event} event`);
    },
  );

  robot.respond(
    /unsubscribe ([a-z0-9\-\.\:_]+)$/i,
    ({match: [_, event], envelope: value}) => {
      const {
        user: {name: key},
      } = value;

      if (subscriptions.unsubscribe(event, key)) {
        msg.send(`Unsubscribed ${key} from ${event} event`);
      } else {
        msg.send(`${key} was not subscribed to ${event} event`);
      }
    },
  );

  robot.respond(
    /unsubscribe all keys from event ([a-z0-9\-\.\:_]+)$/i,
    ({match: [_, event]}) => {
      subscriptions.unsubscribeAllKeysFromEvent(event);
      msg.send(`Unsubscribed all keys from event ${event}`);
    },
  );

  robot.respond(
    /unsubscribe all events$/i,
    ({
      envelope: {
        user: {name: key},
      },
    }) => {
      let count = subscriptions.unsubscribeFromAllEvents(key);
      msg.send(`Unsubscribed ${key} from ${count} events`);
    },
  );

  robot.respond(/my subscriptions$/i, ({envelope: {user: {name: key}}}) => {
    let message = '';
    let events = subscriptions.subscribedEventsForKey(key);

    for (let i = 0; i < events.length; i++) {
      let event = events[i];
      message += `* ${event}\n`;
    }
    msg.send(message);
  });
};
