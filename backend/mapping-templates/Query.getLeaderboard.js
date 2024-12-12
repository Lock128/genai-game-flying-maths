export function request(ctx) {
  return {
    version: "2018-05-29",
    operation: "Invoke",
    payload: {
      limit: ctx.args.limit || 10
    }
  };
}

export function response(ctx) {
  return ctx.result;
}