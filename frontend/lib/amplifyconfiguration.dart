const amplifyconfig = ''' {
  "UserAgent": "aws-amplify-cli/2.0",
  "Version": "1.0",
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "UserAgent": "aws-amplify-cli/0.1.0",
        "Version": "0.1.0",
        "IdentityManager": {
          "Default": {}
        },
        "Auth": {
            "Default": {
                "authenticationFlowType": "USER_SRP_AUTH",
                "socialProviders": [],
                "usernameAttributes": ["EMAIL"],
                "signupAttributes": ["EMAIL"],
                "passwordProtectionSettings": {
                    "passwordPolicyMinLength": 8,
                    "passwordPolicyCharacters": []
                },
                "verificationMechanisms": ["EMAIL"]
            }
        },
        "CredentialsProvider": {
          "CognitoIdentity": {
            "Default": {
              "PoolId": "eu-central-xxx",
              "Region": "eu-central-1"
            }
          }
        },
        "CognitoUserPool": {
          "Default": {
            "PoolId": "eu-central-xxx",
            "AppClientId": "xxx",
            "Region": "eu-central-1"
          }
        }
      }
    }
  },
  "api": {
    "plugins": {
      "awsAPIPlugin": {
        "default": {
          "endpointType": "GraphQL",
          "endpoint": "https://xxx.appsync-api.eu-central-1.amazonaws.com/graphql",
          "region": "eu-centrqal-1",
          "authorizationType": "API_KEY",
          "apiKey": "da2-xxx"
        }
      }
    }
  }
}
''';