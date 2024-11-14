#!/usr/bin/env node
import 'source-map-support/register';
import { App } from 'aws-cdk-lib';
import { FlyingMathsBackendStack } from '../src/backend-stack';

const app = new App();
new FlyingMathsBackendStack(app, 'FlyingMathsBackendStack');