
module.exports = async (res, text) => {
  const { robot: { adapter }, message } = res;
  const { bot: session, flows } = adapter;
  const { metadata: { room }, id: originalMessageId } = message;

  const flow = flows.find((flow) => flow.id == room);

  const [_match, organization, flowName] = /api.flowdock.com\/flows\/([^\/]*)\/([^\/]*)/.exec(flow.url)

  const edit = (messageId) => (content) => new Promise(
    (resolve, reject) => session.editMessage(
      flowName,
      organization,
      messageId,
      { content },
      (err, msg, res) => resolve()
    )
  );

  const send = (content) => new Promise(
    (resolve, reject) =>
      session.comment(
        room,
        originalMessageId,
        content,
        [],
        (err, msg, res) => resolve(msg.id)
      )
  );

  const messageId = await send(text);

  return {
    edit: edit(messageId),
  }
}
