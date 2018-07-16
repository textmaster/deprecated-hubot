// Description:
//   Listen for webhooks and broadcast them to hubot listeners.
//
// Author:
//   gottfrois

module.exports = function (robot) {
  const webhook = ({path, event}) => {
    const handler = (req, res) => {
      let data = (req.body.payload != null) ? JSON.parse(req.body.payload) : req.body;
      robot.emit(event, data);
      res.send('OK');
    };

    robot.router.post(path, handler);
  };

  webhook({path: '/hubot/cloud66-events/deploy', event: 'cloud66-deploy'});
  webhook({path: '/hubot/cloud66-events/build', event: 'cloud66-build'});
  webhook({path: '/hubot/semaphore-events/deploy', event: 'semaphore-deploy'});
  webhook({path: '/hubot/semaphore-events/build', event: 'semaphore-build'});
};
