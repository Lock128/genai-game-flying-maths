import { DynamoDBClient, ReturnValue } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, UpdateCommand, PutCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const dynamoDB = DynamoDBDocumentClient.from(client);


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
    ReturnValues: 'ALL_NEW' as ReturnValue
  };

  try {
    const result = await dynamoDB.send(new UpdateCommand(params));
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
    await dynamoDB.send(new PutCommand({
      TableName: process.env.LEADERBOARD_TABLE!,
      Item: gameResult,
    }));

    return gameResult;
  } catch (error) {
    console.error('Error ending game:', error);
    throw new Error('Failed to end game');
  }
};