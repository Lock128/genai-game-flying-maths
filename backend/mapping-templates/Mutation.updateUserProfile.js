export function request(ctx) {
  return {
    version: "2018-05-29",
    operation: "Invoke",
    payload: {
      userId: ctx.identity.sub,
      ...ctx.args.input
    }
  };
}

export function response(ctx) {
  return ctx.result;
}