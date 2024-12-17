import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, ScanCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const dynamoDB = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.GAME_RESULTS_TABLE;

exports.handler = async (event: any) => {
  console.log('Event:', JSON.stringify(event, null, 2));
  
  try {
    const limit = event.arguments?.limit || 10;
    
    const params = {
      TableName: TABLE_NAME,
      Limit: limit,
      ProjectionExpression: 'gameId, playerName, correctAnswers, totalChallenges, completionTime, #date',
      ExpressionAttributeNames: {
        '#date': 'date'
      }
    };

    const data = await dynamoDB.send(new ScanCommand(params));
    
    if (!data.Items) {
      return [];
    }
    
    const leaderboardEntries = data.Items
      .map(item => ({
        gameId: item.gameId,
        playerName: item.playerName || 'Anonymous',
        score: Math.round((item.correctAnswers / item.totalChallenges) * 100),
        completionTime: item.completionTime || 0,
        date: item.date
      }))
      .sort((a, b) => {
        // First sort by score (descending)
        if (b.score !== a.score) {
          return b.score - a.score;
        }
        // Then by completion time (ascending)
        return a.completionTime - b.completionTime;
      });
    
    return leaderboardEntries;
  } catch (error) {
    console.error('Error:', error);
    throw error;
  }
};