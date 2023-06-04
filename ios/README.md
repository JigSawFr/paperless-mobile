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

## iOS Specificites
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

### Work in Progress...