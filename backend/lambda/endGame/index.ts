import { DynamoDB } from 'aws-sdk';

const dynamoDB = new DynamoDB.DocumentClient();

exports.handler = async (event: any) => {
  const { gameId } = event.arguments;
  const userId = event.identity.sub;

  const params = {
    TableName: process.env.GAMES_TABLE!,
    Key: { id: gameId },
    ConditionExpression: 'userId = :userId',
    UpdateExpression: 'SET endTime = :endTime',
    ExpressionAttributeValues: {
      ':userId': userId,
      ':endTime': new Date().toISOString(),
    },
    ReturnValues: 'ALL_NEW',
  };

  try {
    const result = await dynamoDB.update(params).promise();
    const game = result.Attributes;

    // Add null check before accessing game properties
    if (!game) {
      return {
        statusCode: 404,
        body: JSON.stringify({ message: 'Game not found' })
      };
    }
    const totalChallenges = game.challenges.length;
    const correctAnswers = game.challenges.filter((c: any) => c.correctAnswer === c.userAnswer).length;
    const completionTime = Math.floor((new Date(game.endTime).getTime() - new Date(game.startTime).getTime()) / 1000);

    const gameResult = {
      gameId,
      userId,
      totalChallenges,
      correctAnswers,
      completionTime,
    };

    // Save game result to a separate table for leaderboard
    await dynamoDB.put({
      TableName: process.env.LEADERBOARD_TABLE!,
      Item: gameResult,
    }).promise();

    return gameResult;
  } catch (error) {
    console.error('Error ending game:', error);
    throw new Error('Failed to end game');
  }
};