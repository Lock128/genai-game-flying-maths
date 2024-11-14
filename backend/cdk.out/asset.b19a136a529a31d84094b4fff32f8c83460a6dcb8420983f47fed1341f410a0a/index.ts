import { DynamoDB } from 'aws-sdk';

const dynamoDB = new DynamoDB.DocumentClient();

exports.handler = async (event: any) => {
  const { limit = 10 } = event.arguments;

  const params = {
    TableName: process.env.LEADERBOARD_TABLE!,
    IndexName: 'ByScore',
    KeyConditionExpression: 'dummy = :dummy',
    ExpressionAttributeValues: {
      ':dummy': 1,
    },
    ScanIndexForward: false,
    Limit: limit,
  };

  try {
    const result = await dynamoDB.query(params).promise();
    return result.Items;
  } catch (error) {
    console.error('Error getting leaderboard:', error);
    throw new Error('Failed to get leaderboard');
  }
};