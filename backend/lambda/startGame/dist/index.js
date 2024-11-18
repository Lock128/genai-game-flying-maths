"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_dynamodb_1 = require("@aws-sdk/client-dynamodb");
const lib_dynamodb_1 = require("@aws-sdk/lib-dynamodb");
const uuid_1 = require("uuid");
const client = new client_dynamodb_1.DynamoDBClient({});
const dynamoDB = lib_dynamodb_1.DynamoDBDocumentClient.from(client);
function generateMathProblem(grade) {
    // Implement logic to generate age-appropriate math problems based on grade
    // This is a placeholder implementation
    const num1 = Math.floor(Math.random() * 10) + 1;
    const num2 = Math.floor(Math.random() * 10) + 1;
    return {
        problem: `${num1} + ${num2}`,
        correctAnswer: num1 + num2
    };
}
exports.handler = async (event) => {
    const userId = event.identity.sub;
    const gameId = (0, uuid_1.v4)();
    // Get user's grade from DynamoDB
    const userParams = {
        TableName: process.env.USER_PROFILE_TABLE,
        Key: { userId }
    };
    try {
        const userResult = await dynamoDB.send(new lib_dynamodb_1.GetCommand(userParams));
        const userGrade = userResult.Item?.grade || 1;
        const challenges = Array.from({ length: 10 }, () => {
            const { problem, correctAnswer } = generateMathProblem(userGrade);
            return {
                id: (0, uuid_1.v4)(),
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
            TableName: process.env.GAMES_TABLE,
            Item: game
        };
        await dynamoDB.send(new lib_dynamodb_1.PutCommand(gameParams));
        return game;
    }
    catch (error) {
        console.error('Error starting game:', error);
        throw new Error('Failed to start game');
    }
};
