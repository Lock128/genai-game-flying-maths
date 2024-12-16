import { AppSyncIdentityCognito, AppSyncIdentityIAM } from 'aws-lambda';

export interface UserIdentity {
  userId: string;
  isAnonymous: boolean;
}

export function getUserIdentity(identity: AppSyncIdentityCognito | AppSyncIdentityIAM): UserIdentity {
  if ('sub' in identity) {
    // Authenticated Cognito user
    return {
      userId: identity.sub,
      isAnonymous: false
    };
  } else {
    // Unauthenticated IAM user
    return {
      userId: `anon-${identity.sourceIp.replace(/\./g, '-')}`,
      isAnonymous: true
    };
  }
}