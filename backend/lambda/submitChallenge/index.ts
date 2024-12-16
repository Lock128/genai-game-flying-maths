import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { getUserIdentity } from '../utils';
import { DynamoDBDocumentClient, UpdateCommand, PutCommand, GetCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const dynamoDB = DynamoDBDocumentClient.from(client);

exports.handler = async (event: any) => {
  const { gameId, challengeId, answer } = event.arguments;
  const { userId } = getUserIdentity(event.identity);

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
    const result = await dynamoDB.send(new GetCommand(params));
    const game = result.Item;
    
    // Add null check before accessing game properties
    if (!game) {
      return {
        statusCode: 404,
        body: JSON.stringify({ message: 'Game not found' })
      };
    }
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

    console.log(updateParams);

    const result2 = await dynamoDB.send(new UpdateCommand(updateParams));

    return isCorrect;
  } catch (error) {
    console.error('Error submitting challenge:', error);
    throw new Error('Failed to submit challenge');
  }
};