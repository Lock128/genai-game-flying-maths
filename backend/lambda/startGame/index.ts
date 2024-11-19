import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, UpdateCommand, PutCommand, GetCommand } from '@aws-sdk/lib-dynamodb';
import { v4 as uuidv4 } from 'uuid';
import { generateMathProblem } from '../../src/mathUtils';


const client = new DynamoDBClient({});
const dynamoDB = DynamoDBDocumentClient.from(client);


// Math problem generation moved to mathUtils.ts

exports.handler = async (event: any) => {
  const difficulty = event.arguments.difficulty || 'medium';
  const userId = event.identity.sub;
  const gameId = uuidv4();

  // Get user's grade from DynamoDB
  const userParams = {
    TableName: process.env.USER_PROFILE_TABLE!,
    Key: { userId }
  };

  try {
    const userResult = await dynamoDB.send(new GetCommand(userParams));

    const userGrade = userResult.Item?.grade || 1;

    const challenges = Array.from({ length: 5 }, () => {
      const { problem, answer } = generateMathProblem(difficulty);
      return {
        id: uuidv4(),
        problem,
        correctAnswer: answer
      };
    });

    const game = {
      id: gameId,
      userId,
      startTime: new Date().toISOString(),
      challenges,
      totalAnswered: 0,
      correctAnswers: 0
    };

    // Save game to DynamoDB
    const gameParams = {
      TableName: process.env.GAMES_TABLE!,
      Item: game
    };

    await dynamoDB.send(new PutCommand(gameParams));

    return game;
  } catch (error) {
    console.error('Error starting game:', error);
    throw new Error('Failed to start game');
  }
};