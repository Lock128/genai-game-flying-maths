export function request(ctx) {
  return {
    version: "2018-05-29",
    operation: "Invoke",
    payload: {
      gameId: ctx.args.gameId
    }
  };
}

export function response(ctx) {
  return ctx.result;
}