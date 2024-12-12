export function request(ctx) {
  const userId = ctx.identity.sub || `anonymous-${util.autoId()}`;
  return {
    version: "2018-05-29",
    operation: "PutItem",
    key: {
      id: { S: util.autoId() },
      userId: { S: userId }
    },
    attributeValues: {
      startTime: { S: new Date().toISOString() },
      difficulty: { S: ctx.args.difficulty },
      status: { S: "IN_PROGRESS" },
      isAuthenticated: { BOOL: ctx.identity.sub != null }
    }
  };
}

export function response(ctx) {
  return ctx.result;
}