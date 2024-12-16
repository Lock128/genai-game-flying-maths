import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';

export function createUnauthenticatedRole(scope: Construct, cognitoIdentityPool: string): iam.Role {
  const unauthenticatedRole = new iam.Role(scope, 'UnauthenticatedRole', {
    assumedBy: new iam.FederatedPrincipal(
      'cognito-identity.amazonaws.com',
      {
        StringEquals: {
          'cognito-identity.amazonaws.com:aud': cognitoIdentityPool,
        },
        'ForAnyValue:StringLike': {
          'cognito-identity.amazonaws.com:amr': 'unauthenticated',
        },
      },
      'sts:AssumeRoleWithWebIdentity'
    ),
  });

  // Add policy for unauthenticated access to AppSync API with rate limiting
  unauthenticatedRole.addToPolicy(
    new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      actions: ['appsync:GraphQL'],
      resources: ['*'], // Will be limited by AppSync authorization config
      conditions: {
        'ForAllValues:StringLike': {
          'aws:RequestTag/Operation': [
            'startGame',
            'submitChallenge',
            'endGame',
            'getGameResult',
            'getLeaderboard'
          ]
        }
      }
    })
  );

  return unauthenticatedRole;
}