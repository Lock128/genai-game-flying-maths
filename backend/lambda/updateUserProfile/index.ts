import { DynamoDB } from 'aws-sdk';

const dynamoDB = new DynamoDB.DocumentClient();

exports.handler = async (event: any) => {
  const { language, grade } = event.arguments.input;
  const userId = event.identity.sub;

  const params = {
    TableName: process.env.USER_PROFILE_TABLE!,
    Key: { userId },
    UpdateExpression: 'set #language = :language, #grade = :grade',
    ExpressionAttributeNames: {
      '#language': 'language',
      '#grade': 'grade'
    },
    ExpressionAttributeValues: {
      ':language': language,
      ':grade': grade
    },
    ReturnValues: 'ALL_NEW'
  };

  try {
    const result = await dynamoDB.update(params).promise();
    return result.Attributes;
  } catch (error) {
    console.error('Error updating user profile:', error);
    throw new Error('Failed to update user profile');
  }
};