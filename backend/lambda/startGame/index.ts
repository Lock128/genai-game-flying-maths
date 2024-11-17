import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, UpdateCommand, PutCommand } from '@aws-sdk/lib-dynamodb';
import { v4 as uuidv4 } from 'uuid';


const client = new DynamoDBClient({});
const dynamoDB = DynamoDBDocumentClient.from(client);


function generateMathProblem(grade: number): { problem: string; correctAnswer: number } {
  // Implement logic to generate age-appropriate math problems based on grade
  // This is a placeholder implementation
  const num1 = Math.floor(Math.random() * 10) + 1;
  const num2 = Math.floor(Math.random() * 10) + 1;
  return {
    problem: `${num1} + ${num2}`,
    correctAnswer: num1 + num2
  };
}

exports.handler = async (event: any) => {
  const userId = event.identity.sub;
  const gameId = uuidv4();

  // Get user's grade from DynamoDB
  const userParams = {
    TableName: process.env.USER_PROFILE_TABLE!,
    Key: { userId }
  };

  try {
    const userResult = await dynamoDB.get(userParams).promise();
    const userGrade = userResult.Item?.grade || 1;

    const challenges = Array.from({ length: 10 }, () => {
      const { problem, correctAnswer } = generateMathProblem(userGrade);
      return {
        id: uuidv4(),
        problem,
        correctAnswer
      };
    });

    const game = {
      id: gameId,
      userId,
      startTime: new Date().toISOString(),
      challenges
    };

    // Save game to DynamoDB
    const gameParams = {
      TableName: process.env.GAMES_TABLE!,
      Item: game
    };

    await dynamoDB.put(gameParams).promise();

    return game;
  } catch (error) {
    console.error('Error starting game:', error);
    throw new Error('Failed to start game');
  }
};