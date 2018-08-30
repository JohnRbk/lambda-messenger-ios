# LambdaMessenger iOS
<img src="Images/lamb-launchscreen.png" alt="lamb" width="100"/>

LambdaMessenger is a chat app that works with the [LambdaMessenger API](https://github.com/JohnRbk/lambda-messenger-api). It was developed in an effort to evaluate [AWS AppSync](https://aws.amazon.com/appsync/) and [AppSync Realtime Data](https://docs.aws.amazon.com/appsync/latest/devguide/real-time-data.html)

## Getting Started

1. Follow the instructions for the [LambdaMessenger API](https://github.com/JohnRbk/lambda-messenger-api) to configure FireBase, AWS AppSync, and deploy the API services for LambdaMessenger.
2. Follow the [FirebaseAuth](https://firebase.google.com/docs/auth/ios/phone-auth?authuser=0) instructions for enabling SMS notifications and for generating a GoogleService-Info.plist file.
3. Run Carthage to download project dependencies `carthage update --platform iOS`
4. Because AWS AppSync does not support Carthage, you need to download that separetely. Additionally, a quirk with the AWS AppSync SDK makes it difficult to use it with OpenID tokens. As a workaround, navigate to the `LambdaMessenger/Frameworks` directory and `git clone https://github.com/JohnRbk/aws-mobile-appsync-sdk-ios` a copy of a patched AWS AppSync SDK. See this [pull request](https://github.com/awslabs/aws-mobile-appsync-sdk-ios/pull/62) for more details.
5. The `LambdaMessenger/API.swift` file is generated from `aws-appsync-codegen`. Use the [LambdaMessenger API](https://github.com/JohnRbk/lambda-messenger-api) project to generate `API.swift` if any updates are made to the AppSync schema.

## Built With

* [AWS AppSync](https://docs.aws.amazon.com/appsync)
* [AWS Lambda](https://aws.amazon.com/documentation/lambda/)
* [AWS DynamoDB](https://aws.amazon.com/documentation/dynamodb/)
* [Firebase](https://firebase.google.com/)
* [Feather Icons](https://feathericons.com/)

## Authors

* John Robokos

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE) file for details
