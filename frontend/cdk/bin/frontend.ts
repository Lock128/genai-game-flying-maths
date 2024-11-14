#!/usr/bin/env node
import 'source-map-support/register';
import { FlyingMathsFrontendStack } from '../lib/frontend-stack';
import { App } from 'aws-cdk-lib';

const app = new App();
new FlyingMathsFrontendStack(app, 'FlyingMathsFrontendStack', {
    env: {
      account: process.env.CDK_DEFAULT_ACCOUNT,
      region: process.env.CDK_DEFAULT_REGION
    }
    // ... rest of your stack configuration
  });
//start