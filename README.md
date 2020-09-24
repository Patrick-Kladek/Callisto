# Callisto
[![Twitter: @PatrickKladek](https://img.shields.io/badge/twitter-@PatrickKladek-orange.svg?style=flat)](https://twitter.com/PatrickKladek)
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://raw.githubusercontent.com/IdeasOnCanvas/Callisto/master/LICENSE)
![alt text](https://img.shields.io/badge/Platform-Mac%2010.12+-blue.svg "Target Mac")


![Logo](https://raw.githubusercontent.com/IdeasOnCanvas/Callisto/main/Documentation/Callisto%20Workflow%20Image.png "Logo")

Clang Static Analyzer is great, it catches lots of potential bugs and errors in your code. It has one downside though: running the Clang Static Analyzer every time you build your project takes a lot of time, and we all could use some shorter build times. Callisto solves this problem, as it allows you to run the Clang Static Analyzer on your build server (e.g. Buildkite) and posts the results to our favorite messaging tool Slack.

### Installation

Checkout the repo, open the project and build it. You can find the binary in the Products folder in Xcode. We recomend to checkin the binary in your project.

### Usage

Callisto runs in two steps. First it will sumarize the build log. In the second step it will post the results to Github and Slack.

#### Summarize

If you have multiple targets in your project run this step for each of them. For faster runs you can build each target on its own machine. With Buildkite it's possible to mark the created file as build artefact - this way it will be available on all buildservers (needed for the next step).

```
#!/bin/bash

./Callisto summarise -fastlane '/tmp/fastlane_log.txt' -output .
```

To get the log from fastlane you can pipe its output through a file:

```
#!/bin/bash

fastlane ios static_analyze 2>&1 | tee /tmp/fastlane_iOS_Output.txt
```

If you use Jenkins its a bit easier:

```
#!/bin/bash

writeFile(file: "build-${env.BUILD_NUMBER}.txt", text: currentBuild.rawBuild.getLog(1000000).join('\n'), encoding: 'utf-8')

```

#### Comment on Github

When all sumarize tasks finished you can post the build result to Github. 
We recommend adding a new user to your github repo - we called it bot and created a personal access token for this account. Give it full access to `repo & users`. This token is then used by Callisto via a command line argument. Depending on your CI you can add this as a secret variable.

We used some files which were included in multiple targets, therefore we got duplicated warnings & errors. To fix this Callisto is able to detect such cases and will correctly mark duplicated warnings & errors. Just make sure to add all .buildReport files.

```
#!/bin/bash

./Callisto upload 
	-githubToken $access_token 
	-githubOrganisation $organisation 
	-githubRepository $repo
	-branch $branch_name
	-deletePreviousComments YES
	-ignore "todo, -Wpragma"
	-files "./macTarget.buildReport ./iosTarget.buildReport"
```

#### Comment on Slack

If would rather be notified about a failed build in slack use this command:

```
#!/bin/bash

./Callisto slack 
	-slackURL $slack_webhook
	-githubToken $access_token
	-githubOrganisation $organisation
	-githubRepository $repo
	-branch '${env.BRANCH_NAME}'
	-ignore "todo, -Wpragma"
	-files "./macTarget.buildReport ./iosTarget.buildReport"
```

#### fastlane static_analyze lane:
The important thing here is `xcargs: "analyze"`. If you don't want to run the static analyzer and only post build errors & warnings to slack just remove the `"analyze"` from `xcargs`.

```ruby
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
      xcargs: "analyze"
    )
  end
end
```

### Parameters

* `-slack`: create a Slack Webhook URL and pass it as a parameter to Callisto, to enable posting to Slack
* `-branch`: when using Buildkite you can simply pass the environment variable "$BUILDKITE_BRANCH"
* `-githubUsername`: The username of a GitHub account that has access to your repository
* `-githubToken`: The recommended way to safely connect to GitHub: create a token for your user
* `-githubOrganisation`: needed to create the correct URL for communicating with GitHub
* `-githubRepository`: needed to create the correct URL for communicating with GitHub
* `-ignore`: pass keywords which should be excluded from your Slack report, e.g. you can exclude "todo"
* `-deletePreviousComments` Used only for github. When set to `YES` only the lastest build summary is visible in your Pull Request.

### How does it work?

Callisto simply parses the output from *fastlane*, which mostly pipes through the Clang Static Analyzer messages from the compiler. By filtering these messages and reformatting them Callisto is able to post only the relevant information to Slack. In addition to that, if you enable GitHub-Checks you can also block Pull Request from being merged, if Callisto finds an issue in your code.

Callisto is brought to you by [IdeasOnCanvas](http://ideasoncanvas.com), the creator of MindNode for iOS, macOS & watchOS.
