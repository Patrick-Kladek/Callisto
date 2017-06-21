# Callisto
[![Twitter: @PatrickKladek](https://img.shields.io/badge/twitter-@PatrickKladek-orange.svg?style=flat)](https://twitter.com/PatrickKladek)
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://raw.githubusercontent.com/IdeasOnCanvas/Callisto/master/LICENSE)
![alt text](https://img.shields.io/badge/Platform-Mac%2010.12+-blue.svg "Target Mac")


![Logo](https://raw.githubusercontent.com/IdeasOnCanvas/Callisto/master/Documentation/Callisto%20Workflow%20Image.png "Logo")

Clang Static Analyzer is great, it catches lots of potential bugs and errors in your code. It has one downside though: running the Clang Static Analyzer every time you build your project takes a lot of time, and we all could use some shorter build times. Callisto solves this problem, as it allows you to run the Clang Static Analyzer on your build server (e.g. Buildkite) and posts the results to our favorite messaging tool Slack.

```
#!/bin/bash

fastlane ios staticAnalyze 2>&1 | tee /tmp/fastlane_iOS_Output.txt
Callisto -fastlane "/tmp/fastlane_iOS_Output.txt" \
-slack "<SLACK_WEBHOOK_URL>" \
-branch "$BUILDKITE_BRANCH" \
-githubUsername "<GITHUB_USERNAME>" \
-githubToken "<GITHUB_TOKEN>" \
-githubOrganisation "<GITHUB_ORGANISATION>" \
-githubRepository "<GITHUB_REPOSITORY>" \
-ignore "todo, -Wpragma"
```

### Parameters
* -slack: create a slack webhook url and pass as parameter to Callisto
* -branch: when using buildKite you can simply pass the envirmonment variable "$BUILDKITE_BRANCH"
* -githubUsername: Callisto needs access to the github resolve the branch to the associated pull request.
* -githubToken: instead of using your github password create a token from your account and only allow read access to the repository. This way is recomended by GitHub.
* -githubOrganisation: this parameter is used to create the correct url for communicating with guthub.
* -githubRepository: this parameter is used to create the correct url for communicating with guthub.
* -ignore: pass keywords which should be excluded from your slack report. We use "todo & -Wpragma" since we know they are in our code but we don't want to be messaged about it by every push.

### How does it work?
Callisto simply parses the output from Fastlane, which mostly pipes through the Clang Static Analyzer messages from the compiler. By filtering these messages and reformatting them Callisto is able to post only the relevant information to Slack. In addition to that, if you enable GitHub-Checks you can also block Pull Request from being merged, if Callisto finds an issue in your code.
