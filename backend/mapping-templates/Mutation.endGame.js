export function request(ctx) {
  const userId = ctx.identity.sub || `anonymous-${ctx.prev.result.userId}`;
  return {
    version: "2018-05-29",
    operation: "PutItem",
    key: {
      id: { S: ctx.args.gameId },
      userId: { S: userId }
    },
    attributeValues: {
      totalChallenges: { N: ctx.prev.result.totalChallenges.toString() },
      correctAnswers: { N: ctx.prev.result.correctAnswers.toString() },
      completionTime: { N: ctx.prev.result.completionTime.toString() }
    }
  };
}

export function response(ctx) {
  return ctx.result;
}