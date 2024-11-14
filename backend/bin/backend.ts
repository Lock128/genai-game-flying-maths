#!/usr/bin/env node
import 'source-map-support/register';
import { App } from 'aws-cdk-lib';
import { FlyingMathsBackendStack } from '../src/backend-stack';

const app = new App();
new FlyingMathsBackendStack(app, 'FlyingMathsBackendStack',{
    env: {
      account: process.env.CDK_DEFAULT_ACCOUNT,
      region: "eu-central-1"
    }
    // ... rest of your stack configuration
  });