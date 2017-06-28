# Callisto
[![Twitter: @PatrickKladek](https://img.shields.io/badge/twitter-@PatrickKladek-orange.svg?style=flat)](https://twitter.com/PatrickKladek)
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://raw.githubusercontent.com/IdeasOnCanvas/Callisto/master/LICENSE)
![alt text](https://img.shields.io/badge/Platform-Mac%2010.12+-blue.svg "Target Mac")


![Logo](https://raw.githubusercontent.com/IdeasOnCanvas/Callisto/master/Documentation/Callisto%20Workflow%20Image.png "Logo")

Clang Static Analyzer is great, it catches lots of potential bugs and errors in your code. It has one downside though: running the Clang Static Analyzer every time you build your project takes a lot of time, and we all could use some shorter build times. Callisto solves this problem, as it allows you to run the Clang Static Analyzer on your build server (e.g. BuildKite) and posts the results to our favorite messaging tool Slack.

```
#!/bin/bash

fastlane ios static_analyze 2>&1 | tee /tmp/fastlane_iOS_Output.txt
Callisto -fastlane "/tmp/fastlane_iOS_Output.txt" \
-slack "<SLACK_WEBHOOK_URL>" \
-branch "$BUILDKITE_BRANCH" \
-githubUsername "<GITHUB_USERNAME>" \
-githubToken "<GITHUB_TOKEN>" \
-githubOrganisation "<GITHUB_ORGANISATION>" \
-githubRepository "<GITHUB_REPOSITORY>" \
-ignore "todo, -Wpragma"
```

#### fastlane static_analyze lane:
The important thing here is `xcargs: "analyze"`. If you don't want to run the static analyzer and only post build errors & warnings to slack just remove the `"analyze"` from `xcargs`.
```
platform :ios do
    desc "Build and run the static Analyzer"
    lane :staticAnalyze do
        scan(
             devices: [
                "iPhone 6s"
             ],
             clean: true,
             workspace: "MyWorkspace.xcworkspace",
             scheme: "MyProject for iOS",
             xcargs: "CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY='' IDEBuildOperationMaxNumberOfConcurrentCompileTasks=1 analyze"
        )
    end
end
```

### Parameters
* `-slack`: create a Slack Webhook URL and pass it as a parameter to Callisto, to enable posting to Slack
* `-branch`: when using BuildKite you can simply pass the environment variable "$BUILDKITE_BRANCH"
* `-githubUsername`: The username of a GitHub account that has access to your repository
* `-githubToken`: The recommended way to safely connect to GitHub: create a token for your user
* `-githubOrganisation`: needed to create the correct URL for communicating with GitHub
* `-githubRepository`: needed to create the correct URL for communicating with GitHub
* `-ignore`: pass keywords which should be excluded from your Slack report, e.g. you can exclude "todo"

### How does it work?
Callisto simply parses the output from *fastlane*, which mostly pipes through the Clang Static Analyzer messages from the compiler. By filtering these messages and reformatting them Callisto is able to post only the relevant information to Slack. In addition to that, if you enable GitHub-Checks you can also block Pull Request from being merged, if Callisto finds an issue in your code.

Callisto is brought to you by [IdeasOnCanvas](http://ideasoncanvas.com), the creator of MindNode for iOS, macOS & watchOS.
