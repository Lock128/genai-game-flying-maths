# genai-game-flying-maths

This repository contains the source code for a Web-Game that allows players to solve simple maths problems for students/kids from the age of 6 up to 10.
It is available in English and German. The language is configurable on demand and can be stored in the user account.

The user account is handled through AWS Cognito and users are able to sign up if they wish.
No other information are collected but the signup email, a user name, the password, the user language and the grade of the users.
The user profile information are also stored in a DynamoDB in the backend.

## Game mechanichs
The game works in a way that the user can start a game on demand. In that case, a series of 10 simple math problems will be generated (e.g. 25+5+10, 5*24, 5*4, ...).
After these have been generated, the user will be presented one of the challenges one after another. When the challenge is presented, on the lower part of the screen a few possible "results" are presented. The move automatically from the left side of the screen to the right one. They are clickable items and the user needs to click or tab on the correct result. 
If the selection is correct, the item becomes green and the next challenge is shown.
if the selection is wrong, the item becomes red, the correct result is displayed and the next challenge is shown.

At the end of the 10 challenges, the user will be able to see a result of his challenges.

## Languages & Coding
The backend of the code is written in Typescript and uses AWS CDKv2 for infrastructure as code.  It is stored in the "backend" directory.
It also includes a GraphQL endpoint and schema that can be used by the client application. The authentication for the API is handled through Cognito.
The API allows to change user settings, but it also stores events of the user, like "game started" and "solved math challenges" and all information related to a math challenge.
The frontend of the application is hosted on CloudFront and S3 and is written in Flutter. It uses Amplify Flutter as a library to access the backend services (like GraphQL and Cognito).
Both backend and frontend contain everything that they need to work - so both include infrastructure as code.

## CI/CD
The game is deployed using Github Actions. It has dependabot activated for both backend and frontend.
It has two different pipelines, one that builds & deploys the Frontend and is only triggered on commits for the frontend directory. The other pipeline builds and deploys the Backend application.