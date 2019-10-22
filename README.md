# Exercise Instructions



:wave: Hello! Thanks so much for participating in our interview process. We know that it takes time and effort away from other things, and we appreciate it.

This technical exercise is our primary means of understanding your programming abilities and the beginning of our understanding of your qualifications. Build something you are proud of. We expect this will take about two hours but there is no time limit, no penalty for taking longer, and no benefit in going above-and-beyond.

Scenario: Every Friday the Release Manager does a code freeze in preparation for the next release. Currently the Release Manager does all the code freeze work manually. Please implement a command line tool to help us automate our code freeze process, automating as much of the process as possible. 

When designing your tool, consider that it would be used by folks with less technical expertise. The tool should also be able to handle some exceptions and fail gracefully. Feel free to use your favorite programming language and framework (we use Python internally) but the code should be runnable on modern Mac hardware and OS. Plan for the tool to be extended over time, and use of the github API is prefered.

Details:
1. All release versions and release names are defined in the file 'releng/release_info.csv'.
2. The code freeze is being executed for release 'Cake/1.2' defined in 'release.plist' file.
3. Feature Flags settings are stored in the file 'featureflags/FF.csv'.

Your code should be able to do at least the following:
1. Create a separate git branch to represent the next new release.
2. Make sure the release file (release.plist) reflects the next release name and version.
3. Generate a feature flag report (text file is fine) to see what feature flags have changed since the last release.

Requirements:
1. Please create a dev branch 'release-dev' out of this repo, in your dev branch, create a directory "release-tools" for your code and put all your delieverables under that directory. Note: this 'release-dev' branch is not the release branch.
2. Along with your code, include a write up of the test cases you would create in a text file in the "release-tools" directory. There is no need to create real tests.
3. Once you finish, create a Pull Request against master of this repo.

We don’t expect that you’ll create a production-ready tool in two hours, but we would like you to show us how you create clean, maintainable code. Once you're happy with the result email us that you have completed the challenge.

Good luck! :four_leaf_clover:
