import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { getUserIdentity } from '../utils';
import { DynamoDBDocumentClient, UpdateCommand, PutCommand, GetCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const dynamoDB = DynamoDBDocumentClient.from(client);


exports.handler = async (event: any) => {
  const { gameId } = event.arguments;
  const { userId } = getUserIdentity(event.identity);

  const params = {
    TableName: process.env.GAMES_TABLE!,
    Key: { id: gameId },
    ConditionExpression: 'userId = :userId',
    ExpressionAttributeValues: {
      ':userId': userId,
    },
  };

  try {
    const result = await dynamoDB.send(new GetCommand(params));
    const game = result.Item;

    if (!game) {
      throw new Error('Game not found');
    }

    const totalChallenges = game.challenges.length;
    const correctAnswers = game.challenges.filter((c: any) => c.correctAnswer === c.userAnswer).length;
    const completionTime = Math.floor((new Date(game.challenges[totalChallenges - 1].answeredAt).getTime() - new Date(game.startTime).getTime()) / 1000);

    return {
      gameId,
      userId,
      totalChallenges,
      correctAnswers,
      completionTime,
    };
  } catch (error) {
    console.error('Error getting game result:', error);
    throw new Error('Failed to get game result');
  }
};