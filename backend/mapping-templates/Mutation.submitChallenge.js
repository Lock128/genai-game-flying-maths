export function request(ctx) {
  const userId = ctx.identity.sub || `anonymous-${util.autoId()}`;
  return {
    version: "2018-05-29",
    operation: "UpdateItem",
    key: {
      id: { S: ctx.args.gameId },
      userId: { S: userId }
    },
    update: {
      expression: "SET answers = list_append(if_not_exists(answers, :empty_list), :answer)",
      expressionValues: {
        ":answer": { L: [{ N: ctx.args.answer.toString() }] },
        ":empty_list": { L: [] }
      }
    }
  };
}

export function response(ctx) {
  return ctx.result;
}