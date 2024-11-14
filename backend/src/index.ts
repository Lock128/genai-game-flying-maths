import * as cdk from 'aws-cdk-lib';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as appsync from 'aws-cdk-lib/aws-appsync';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import { Construct } from 'constructs';

class FlyingMathsBackendStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Cognito User Pool
    const userPool = new cognito.UserPool(this, 'FlyingMathsUserPool', {
      selfSignUpEnabled: true,
      signInAliases: { email: true },
      autoVerify: { email: true },
      standardAttributes: {
        email: { required: true, mutable: true },
      },
      customAttributes: {
        'language': new cognito.StringAttribute({ mutable: true }),
        'grade': new cognito.NumberAttribute({ mutable: true }),
      },
    });

    // DynamoDB Tables
    const userProfileTable = new dynamodb.Table(this, 'UserProfileTable', {
      partitionKey: { name: 'userId', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
    });

    const gamesTable = new dynamodb.Table(this, 'GamesTable', {
      partitionKey: { name: 'id', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
    });

    const leaderboardTable = new dynamodb.Table(this, 'LeaderboardTable', {
      partitionKey: { name: 'gameId', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'completionTime', type: dynamodb.AttributeType.NUMBER },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
    });

    leaderboardTable.addGlobalSecondaryIndex({
      indexName: 'ByScore',
      partitionKey: { name: 'dummy', type: dynamodb.AttributeType.NUMBER },
      sortKey: { name: 'correctAnswers', type: dynamodb.AttributeType.NUMBER },
      projectionType: dynamodb.ProjectionType.ALL,
    });

    // Lambda Functions
    const updateUserProfileLambda = new lambda.Function(this, 'UpdateUserProfileLambda', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda/updateUserProfile'),
      environment: {
        USER_PROFILE_TABLE: userProfileTable.tableName,
      },
    });

    const startGameLambda = new lambda.Function(this, 'StartGameLambda', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda/startGame'),
      environment: {
        USER_PROFILE_TABLE: userProfileTable.tableName,
        GAMES_TABLE: gamesTable.tableName,
      },
    });

    const submitChallengeLambda = new lambda.Function(this, 'SubmitChallengeLambda', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda/submitChallenge'),
      environment: {
        GAMES_TABLE: gamesTable.tableName,
      },
    });

    const getGameResultLambda = new lambda.Function(this, 'GetGameResultLambda', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda/getGameResult'),
      environment: {
        GAMES_TABLE: gamesTable.tableName,
      },
    });

    const endGameLambda = new lambda.Function(this, 'EndGameLambda', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda/endGame'),
      environment: {
        GAMES_TABLE: gamesTable.tableName,
        LEADERBOARD_TABLE: leaderboardTable.tableName,
      },
    });

    const getLeaderboardLambda = new lambda.Function(this, 'GetLeaderboardLambda', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda/getLeaderboard'),
      environment: {
        LEADERBOARD_TABLE: leaderboardTable.tableName,
      },
    });

    // Grant Lambda functions access to DynamoDB
    userProfileTable.grantReadWriteData(updateUserProfileLambda);
    userProfileTable.grantReadData(startGameLambda);
    gamesTable.grantReadWriteData(startGameLambda);
    gamesTable.grantReadWriteData(submitChallengeLambda);

    // AppSync API
    const api = new appsync.GraphqlApi(this, 'FlyingMathsApi', {
      name: 'flying-maths-api',
      schema: appsync.SchemaFile.fromAsset('schema/schema.graphql'),
      authorizationConfig: {
        defaultAuthorization: {
          authorizationType: appsync.AuthorizationType.USER_POOL,
          userPoolConfig: { userPool },
        },
      },
    });

    // AppSync Datasources
    const updateUserProfileDS = api.addLambdaDataSource('UpdateUserProfileDataSource', updateUserProfileLambda);
    const startGameDS = api.addLambdaDataSource('StartGameDataSource', startGameLambda);
    const submitChallengeDS = api.addLambdaDataSource('SubmitChallengeDataSource', submitChallengeLambda);
    const getGameResultDS = api.addLambdaDataSource('GetGameResultDataSource', getGameResultLambda);
    const endGameDS = api.addLambdaDataSource('EndGameDataSource', endGameLambda);
    const getLeaderboardDS = api.addLambdaDataSource('GetLeaderboardDataSource', getLeaderboardLambda);

    // AppSync Resolvers
    updateUserProfileDS.createResolver({
      typeName: 'Mutation',
      fieldName: 'updateUserProfile',
    });

    startGameDS.createResolver({
      typeName: 'Mutation',
      fieldName: 'startGame',
    });

    submitChallengeDS.createResolver({
      typeName: 'Mutation',
      fieldName: 'submitChallenge',
    });

    endGameDS.createResolver({
      typeName: 'Mutation',
      fieldName: 'endGame',
    });

    getGameResultDS.createResolver({
      typeName: 'Query',
      fieldName: 'getGameResult',
    });

    getLeaderboardDS.createResolver({
      typeName: 'Query',
      fieldName: 'getLeaderboard',
    });

    // Output
    new cdk.CfnOutput(this, 'UserPoolId', { value: userPool.userPoolId });
    new cdk.CfnOutput(this, 'GraphQLApiUrl', { value: api.graphqlUrl });
  }
}

const app = new cdk.App();
new FlyingMathsBackendStack(app, 'FlyingMathsBackendStack');
app.synth();