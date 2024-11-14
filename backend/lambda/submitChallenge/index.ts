import { DynamoDB } from 'aws-sdk';

const dynamoDB = new DynamoDB.DocumentClient();

exports.handler = async (event: any) => {
  const { gameId, challengeId, answer } = event.arguments;
  const userId = event.identity.sub;

  const params = {
    TableName: process.env.GAMES_TABLE!,
    Key: { id: gameId },
    ConditionExpression: 'userId = :userId',
    UpdateExpression: 'SET challenges = list_append(challenges, :challenge)',
    ExpressionAttributeValues: {
      ':userId': userId,
      ':challenge': [{
        id: challengeId,
        userAnswer: answer,
        answeredAt: new Date().toISOString()
      }]
    },
    ReturnValues: 'ALL_NEW'
  };

  try {
    const result = await dynamoDB.update(params).promise();
    const game = result.Attributes;
    
    const challenge = game.challenges.find((c: any) => c.id === challengeId);
    const isCorrect = challenge.correctAnswer === answer;

    // Update game results
    const updateParams = {
      TableName: process.env.GAMES_TABLE!,
      Key: { id: gameId },
      UpdateExpression: 'SET totalAnswered = totalAnswered + :inc, correctAnswers = correctAnswers + :correct',
      ExpressionAttributeValues: {
        ':inc': 1,
        ':correct': isCorrect ? 1 : 0
      }
    };

    await dynamoDB.update(updateParams).promise();

    return isCorrect;
  } catch (error) {
    console.error('Error submitting challenge:', error);
    throw new Error('Failed to submit challenge');
  }
};