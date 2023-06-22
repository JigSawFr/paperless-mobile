<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
<!-- [![LinkedIn][linkedin-shield]][linkedin-url]-->



<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/astubenbord/paperless-mobile">
    <img src="assets/logos/paperless_logo_green.png" alt="Logo" width="80" height="80">
  </a>

<h2 align="center">Paperless Mobile</h2>

  <p align="center">
    An (almost) fully fledged mobile paperless client.
    <br />
    <br />
    <p>
      <a href="https://play.google.com/store/apps/details?id=de.astubenbord.paperless_mobile">
        <img src="resources/get_it_on_google_play_en.svg" width="140px">
      </a>
    </p>
    <!--<a href="https://github.com/astubenbord/paperless-mobile">View Demo</a>
    ·-->  
    <a href="https://github.com/astubenbord/paperless-mobile/issues">Report Bug</a>
    ·
    <a href="https://github.com/astubenbord/paperless-mobile/discussions/categories/feature-requests">Request Feature</a>
  </p>
</div>

## Important Notice
This project is under **very active** development. Breaking changes are expected and therefore a clean install is recommended for each update!

<!-- ABOUT THE PROJECT -->
## About The Project
Paperless Mobile brings <a href="https://github.com/paperless-ngx/paperless-ngx">paperless-ngx</a> to your smartphone without any compromises. While you can use paperless-ngx from a mobile browser, managing your documents this way is often a tedious and slow process. The app integrates a custom scanner, biometric authentication and many more conveniences to help you make the transition from a paper-based to a fully digital office experience.

### :rocket: Highlights
:heavy_check_mark: **View** your documents at a glance<br>
:heavy_check_mark: **Add**, **delete** or **edit** documents<br>
:heavy_check_mark: **Share**, **download** and **preview** files<br>
:heavy_check_mark: **Manage** and assign labels<br>
:heavy_check_mark: **Scan** and upload documents to paperless<br>
:heavy_check_mark: **Upload existing documents** from other apps via Paperless Mobile<br>
:heavy_check_mark: Easily process and manage new documents in the dedicated **inbox**<br>
:heavy_check_mark: **Search** for documents using a wide range of filter criteria<br>
:heavy_check_mark: **Secure** your data with a **biometric factor**<br>
:heavy_check_mark: Support for **TLS mutual authentication** (client certificates)<br>
:heavy_check_mark: **Modern, intuitive UI** built according to the Material Design 3 specification<br>
:heavy_check_mark: Available in English, German, Polish, French, Catalan, Czech and Turkish language with more to come<br>


### Built With
[![Flutter][Flutter]][Flutter-url]


<!-- GETTING STARTED -->
## Getting Started
To get a local copy up and running follow these simple steps.

### Prerequisites
* Install an IDE of your choice (e.g. VSCode with the Dart/Flutter extensions)
* Install the flutter SDK (https://docs.flutter.dev/get-started/install) _or_ use the flutter git submodule pinned in this project by running `git submodule update --init` inside the project root directory.

### Install dependencies and generate files
1. First, clone the repository:
```sh
git clone https://github.com/astubenbord/paperless-mobile.git
```

You can now run the `scripts/install_dependencies.sh` script at the root of the project, which will automatically install dependencies and generate files for both the app and local packages.

If you want to manually install dependencies and build generated files, you can also run the following commands:

#### Inside the `packages/paperless_api/` folder:
2. Install the dependencies for `paperless_api`
   ```sh
   flutter pub get
   ```
3. Build generated files for `paperless_api`
   ```sh
    flutter pub run build_runner build --delete-conflicting-outputs
   ```
   
#### Inside the project's root folder
4. Install the dependencies for the app
   ```sh
   flutter packages pub get
   ```
5. Build generated files for the app
   ```sh
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```
6. Generate the localization files for the app
   ```sh
   flutter gen-l10n
   ```
   
### Build release version
In order to build a release version, you have to...
1. Exchange the signing configuration in android/app/build.gradle from
```gradle
buildTypes {
    release {
        signingConfig signingConfigs.release
    }
}
```
to 
```gradle
buildTypes {
    release {
        signingConfig signingConfigs.debug
    }
}
```
or use your own signing configuration as described in https://docs.flutter.dev/deployment/android#signing-the-app and leave the `build.gradle` as is.

2. Build the app with release profile (here for android):
```sh
flutter build apk
```
The --release flag is implicit for the build command. You can also run this command with --split-per-abi, which will generate three separate (smaller) binaries.

3. Install the app to your device (when omitting the `--split-per-abi` flag)
```sh
flutter install
```
or when you built with `--split-per-abi`
```sh
flutter install --use-application-binary=build/pp/outputs/flutter-apk/<apk_file_name>.apk
```
  
## Languages and Translations [![Crowdin](https://badges.crowdin.net/paperless-mobile/localized.svg)](https://crowdin.com/project/paperless-mobile)
If you want to contribute by translating a language, feel free to join the [Crowdin](https://crowdin.com/project/paperless-mobile) project!

Thanks to the following contributors for providing translations:
- German and English language translated by  <a href="https://github.com/astubenbord">astubenbord</a>
- Czech language translated by <a href="https://github.com/svetlemodry">svetlemodry</a>
- Turkish language translated by  <a href="https://github.com/imsakg">imsakg</a>
- Polish language translated by <a href="https://github.com/losiu97">losiu97</a>
- French language translated by <a href="https://github.com/JigSawFr">JigSawFr</a>, <a href="https://github.com/SpicyWasab">SpicyWasab</a> and <a href="https://github.com/nathanaelhoun">nathanaelhoun</a>
- Catalan language translated by <a href="https://github.com/rubenix">rubenix</a>

<!-- ROADMAP -->
## Roadmap
- [ ] Fully custom document scanner optimized for common white A4 documents and optimized for the use with Paperless
- [ ] Add more languages
- [x] Support for IOS and publish to AppStore
- [x] Automatic releases and CI/CD with fastlane
- [ ] Templates for recurring scans (e.g. monthly payrolls with same title, dates at end of month, fixed correspondent and document type)

See the [open issues](https://github.com/astubenbord/paperless-mobile/issues) for a full list of issues and [open feature requests](https://github.com/astubenbord/paperless-mobile/discussions/categories/feature-requests) for requested features.

<!-- CONTRIBUTING -->
## Contributing
Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.
All bug reports or feature requests are welcome, even if you can't contribute code!

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'feat: Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<!-- LICENSE -->
## License
Distributed under the GNU General Public License v3.0. See `LICENSE.txt` for more information.

## Donations
I do this in my free time, so if you like the project, consider buying me a coffee! Any donation is much appreciated :^)

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/astubenbord)

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/astubenbord/paperless-mobile.svg?style=for-the-badge
[contributors-url]: https://github.com/astubenbord/paperless-mobile/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/astubenbord/paperless-mobile.svg?style=for-the-badge
[forks-url]: https://github.com/astubenbord/paperless-mobile/network/members
[stars-shield]: https://img.shields.io/github/stars/astubenbord/paperless-mobile.svg?style=for-the-badge
[stars-url]: https://github.com/astubenbord/paperless-mobile/stargazers
[issues-shield]: https://img.shields.io/github/issues/astubenbord/paperless-mobile.svg?style=for-the-badge
[issues-url]: https://github.com/astubenbord/paperless-mobile/issues
[license-shield]: https://img.shields.io/github/license/astubenbord/paperless-mobile.svg?style=for-the-badge
[license-url]: https://github.com/astubenbord/paperless-mobile/blob/main/LICENSE
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/linkedin_username
[product-screenshot]: images/screenshot.png
[Flutter]: https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white
[Flutter-url]: https://flutter.dev

## Contributors
<a href="https://github.com/astubenbord/paperless-mobile/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=astubenbord/paperless-mobile" />
</a>

Made with [contrib.rocks](https://contrib.rocks).

## Troubleshooting
#### Suggestions are not selectable in any of the label form fields
This is a known issue and it has to do with accessibility features of Android. Password managers such as Bitwarden often caused this issue. Luckily, this can be resolved by turning off the accessibility features in these apps. This could also be observed with apps that are allowed to display over other apps, such as emulations of the dynamic island on android.
## I cannot log in since the update to paperless-ngx 1.14.0 (and above).
The app has to somehow get information about it's user from the paperless API. Therefore, the `Users -> View` and the `UISettings -> View` permissions are required for each user trying to log into the app. Otherwise, the app has no way of obtaining your user id and other information required for the usage of most features.