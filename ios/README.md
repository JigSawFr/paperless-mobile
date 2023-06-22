<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/astubenbord/paperless-mobile">
    <img src="../assets/logos/paperless_logo_green.png" alt="Logo" width="80" height="80">
  </a>

<h3 align="center">iOS Building of Paperless Mobile</h3>

  <p align="center">
    Describe how-to package, build and deploy an iOS build !
    <br />
    <br />
    <p>
      <a href="https://testflight.apple.com/join/nmLJvzP9">
        <img src="../resources/get_it_on_testflight_en.png" width="140px">
      </a>
    </p>
    <img alt="Cocoapods platforms" src="https://img.shields.io/cocoapods/p/ios" />
  </p>
</div>

## Important Notice
An **active Apple Developper Subscription** (*recurring cost*) is needed to publish on Apple Testflight and Apple Store ! Your app will also be reviewed by Apple Validation Team before made available on both.
A Macbook is also needed as **Xcode is only available on macOS**.

<!-- GETTING STARTED -->
## Getting Started

To build a release, please follow these steps:

### Prerequisites
* We assume here that you already followed pre-requisites from main README.
* macOS
* Brew
* XCode (min. 14.3)
* XCode Command Line Tools
* Ruby (with rbenv)

## iOS Specifics
### Launcher Icons
> Icons with alpha channel are not allowed in the Apple App Store.

So we need to re-generate them without alpha chanel otherwise our builds will be rejected automatically.
We will use the flutter package `flutter_launcher_icons`

> These steps needs to be done each time we want to change icon of the application

1. Install the package as a dev dependency
```sh
dart pub add dev:flutter_launcher_icons
```
2. We now need to add configuration to `flutter_launcher_icons.yaml`
```sh
flutter_launcher_icons:
  android: true
  ios: true
  remove_alpha_ios: true
  image_path: 'assets/logos/paperless_logo_green.png'
```
3. Run the package to generate icons
```sh
dart run flutter_launcher_icons
```

## Developper Environment Setup
### Env Vars
**fastlane** requires some environment variables set up to run correctly. *In particular, having your locale not set to a UTF-8 locale will cause issues with building and uploading your build.* In your shell profile add the following lines:
```sh
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
```
You can find your shell profile at `~/.bashrc, ~/.bash_profile, ~/.profile or ~/.zshrc` depending on your system.

With nano & ZSH
```sh
nano ~/.zshrc
```
### Installation of Xcode
To proceed installation, search Xcode on AppStore and install it.
### Installation of Xcode Command Line Tools
To proceed installation, execute this command in your terminal:
```sh
xcode-select --install
```
### Install of Ruby Manager (rbenv)
```sh
brew install rbenv ruby-build
```
You now need to load rbenv in your shell
```sh
rbenv init
```
Confirm your installation by using rbenv-doctor
```sh
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-doctor | bash
```
To check fixed version of project
```sh
rbenv versions
```
## Installing of Ruby Gems
We will now install ruby gems
```sh
gem install bundler
```
And install/update gems
```sh
bundle update
```

## Deployment using Fastlane
Reference: https://docs.fastlane.tools/getting-started/ios/setup/
Beta deployement: https://docs.fastlane.tools/getting-started/ios/beta-deployment/

## CI/CD
```sh
bundle install
bundle exec fastlane [lane]
bundle exec fastlane ios sync_match
```

## Contributor cheatsheet
### Ruby
Installation of latest stable release of ruby with rbenv
```sh
rbenv install $(rbenv install -l | grep -v - | tail -1)
#rbenv install -l 2>&1 | grep '^\d' | sort -n | tail -n 1 > .ruby-version # Pick the most recent stable Ruby
```

Fix the version of project to a new version
```sh
rbenv local [version]
```
Content of `./Gemfile`
```
source "https://rubygems.org"

gem "fastlane"
```
Update fastlane gem only
```sh
bundle update fastlane
```
### Fastlane
Initialisation of fastlane
```sh
bundle exec fastlane init
```
List all builds
```sh
bundle exec fastlane pilot builds
```
List of testers
```sh
bundle exec fastlane pilot list
```
Test if authenticated with Git/Github
```sh
ssh -T git@github.com
```

```sh
bundle exec flutter build ipa --export-method development
bundle exec flutter upgrade
bundle exec dart fix --dry-run
bundle exec gem install cocoapods
bundle exec pod install
bundle exec pod update
bundle exec pod --version
bundle exec flutter pub get
bundle exec fastlane beta
```
### Work in Progress...