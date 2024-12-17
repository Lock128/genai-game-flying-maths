import * as cdk from 'aws-cdk-lib';
import * as cognito from 'aws-cdk-lib/aws-cognito';
import * as appsync from 'aws-cdk-lib/aws-appsync';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import * as iam from 'aws-cdk-lib/aws-iam';

import { Construct } from 'constructs';
import path from 'path';

export class FlyingMathsBackendStack extends cdk.Stack {
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

    const userPoolClient = new cognito.UserPoolClient(this, 'FlyingMathsUserPoolClient', {
      userPool,
      generateSecret: false,
    });

    // Create the Identity Pool
    const identityPool = new cognito.CfnIdentityPool(this, 'GameIdentityPool', {
      allowUnauthenticatedIdentities: false, // Set to true if you want to support unauthorized users
      cognitoIdentityProviders: [{
        clientId: userPoolClient.userPoolClientId,
        providerName: userPool.userPoolProviderName,
      }],
      identityPoolName: 'GameIdentityPool'
    });

    // Create roles for authenticated users
    const authenticatedRole = new iam.Role(this, 'CognitoDefaultAuthenticatedRole', {
      assumedBy: new iam.FederatedPrincipal(
        'cognito-identity.amazonaws.com',
        {
          StringEquals: {
            'cognito-identity.amazonaws.com:aud': identityPool.ref,
          },
          'ForAnyValue:StringLike': {
            'cognito-identity.amazonaws.com:amr': 'authenticated',
          },
        },
        'sts:AssumeRoleWithWebIdentity'
      ),
    });

    // Attach the role to the identity pool
    new cognito.CfnIdentityPoolRoleAttachment(this, 'IdentityPoolRoleAttachment', {
      identityPoolId: identityPool.ref,
      roles: {
        authenticated: authenticatedRole.roleArn,
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

    const BUNDLE_OPTIONS = {
      bundling: {
        image: cdk.DockerImage.fromRegistry('node:18'), // Use Node.js image instead of Alpine
        command: [
          'sh', '-c',
          `
            mkdir -p /asset-output && \
            ls -al && \
            cp -r . /tmp/build && \
            cd /tmp/build && \
            npm ci && \
            npm run build && \
            cp -r dist/* /asset-output/ && \
            cp package.json /asset-output/ && \
            cp package-lock.json /asset-output/ && \            
            cd /asset-output && \
            ls -al && \
            npm ci --production && \
            rm -rf node_modules/.package-lock.json
            `
        ],
        user: 'root'
      }
    };
    const startGameLambda = new lambda.Function(this, 'StartGameLambda', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      timeout: cdk.Duration.seconds(30),
      code: lambda.Code.fromAsset(path.join(__dirname, '../lambda/startGame'), BUNDLE_OPTIONS),
      environment: {
        USER_PROFILE_TABLE: userProfileTable.tableName,
        GAMES_TABLE: gamesTable.tableName,
      },
    });

    const submitChallengeLambda = new lambda.Function(this, 'SubmitChallengeLambda', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      timeout: cdk.Duration.seconds(30),
      code: lambda.Code.fromAsset(path.join(__dirname, '../lambda/submitChallenge'), BUNDLE_OPTIONS),
      environment: {
        GAMES_TABLE: gamesTable.tableName,
      },
    });

    const getGameResultLambda = new lambda.Function(this, 'GetGameResultLambda', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset(path.join(__dirname, '../lambda/getGameResult'), BUNDLE_OPTIONS),
      environment: {
        GAMES_TABLE: gamesTable.tableName,
      },
    });

    const endGameLambda = new lambda.Function(this, 'EndGameLambda', {
      runtime: lambda.Runtime.NODEJS_18_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset(path.join(__dirname, '../lambda/endGame'), BUNDLE_OPTIONS),
      environment: {
        GAMES_TABLE: gamesTable.tableName,
        LEADERBOARD_TABLE: leaderboardTable.tableName,
      },
    });

    const getLeaderboardLambda = new lambda.Function(this, 'GetLeaderboardLambda', {
      runtime: lambda.Runtime.NODEJS_18_X,

      handler: 'index.handler',
      code: lambda.Code.fromAsset(path.join(__dirname, '../lambda/getLeaderboard'), BUNDLE_OPTIONS),
      environment: {
        LEADERBOARD_TABLE: leaderboardTable.tableName,
      },
    });

    // Grant Lambda functions access to DynamoDB
    userProfileTable.grantReadWriteData(updateUserProfileLambda);
    userProfileTable.grantReadData(startGameLambda);
    gamesTable.grantReadWriteData(startGameLambda);
    gamesTable.grantReadWriteData(submitChallengeLambda);
    gamesTable.grantReadData(getGameResultLambda);
    gamesTable.grantReadWriteData(endGameLambda);
    leaderboardTable.grantReadWriteData(endGameLambda);
    leaderboardTable.grantReadData(getLeaderboardLambda);

    // AppSync API
    const api = new appsync.GraphqlApi(this, 'FlyingMathsApi', {
      name: 'flying-maths-api',
      schema: appsync.SchemaFile.fromAsset('schema/schema.graphql'),
      authorizationConfig: {
        defaultAuthorization: {
          authorizationType: appsync.AuthorizationType.USER_POOL,
          userPoolConfig: {
            userPool,
          },
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
    updateUserProfileDS.createResolver('updateUserProfile', {
      typeName: 'Mutation',
      fieldName: 'updateUserProfile',
    });

    startGameDS.createResolver('startGame', {
      typeName: 'Mutation',
      fieldName: 'startGame',
    });

    submitChallengeDS.createResolver('submitChallenge', {
      typeName: 'Mutation',
      fieldName: 'submitChallenge',
    });

    endGameDS.createResolver('endGame', {
      typeName: 'Mutation',
      fieldName: 'endGame',
    });

    getGameResultDS.createResolver('getGameResult', {
      typeName: 'Query',
      fieldName: 'getGameResult',
    });

    getLeaderboardDS.createResolver('getLeaderboard', {
      typeName: 'Query',
      fieldName: 'getLeaderboard',
    });

    authenticatedRole.addToPolicy(new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: [
        'appsync:GraphQL'
      ],
      resources: [
        // Add your AppSync API ARN here
        `arn:aws:appsync:${this.region}:${this.account}:apis/${api.apiId}/*`
      ],
    }));

    // Output
    // Add getLeaderboard Lambda data source and resolver
    const getLeaderboardDataSource = api.addLambdaDataSource(
      'GetLeaderboardDataSource',
      getLeaderboardLambda
    );

    getLeaderboardDataSource.createResolver('GetLeaderboardResolver', {
      typeName: 'Query',
      fieldName: 'getLeaderboard',
    });

    new cdk.CfnOutput(this, 'UserPoolId', { value: userPool.userPoolId });
    new cdk.CfnOutput(this, 'UserPoolClientId', { value: userPoolClient.userPoolClientId });
    new cdk.CfnOutput(this, 'GraphQLApiUrl', { value: api.graphqlUrl });

    new cdk.CfnOutput(this, 'IdentityPoolId', {
      value: identityPool.ref,
    });
  }
}

