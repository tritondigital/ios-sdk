# Triton Digital® Mobile SDK for iOS

The Triton Digital® Mobile SDK is designed to help you play your radio station or display on-demand advertisements very easily in your own application. There are two (2) versions of the mobile SDK; one for Android and one for iOS. This is the iOS version.
 
The Triton Digital® Mobile SDK for iOS includes a [ZIP file](https://github.com/tritondigital/ios-sdk/releases) that contains the API reference, and a sample application that is ready to compile showing the most common uses of the SDK.

The Triton Digital® Mobile SDK for iOS adds about 8 MB to the size of your iOS mobile application. This may vary with updates, and according to the parameters that you use.
 
The main features of the SDK include:

- Play Triton Digital® streams (including HLS mounts);
- Receive meta-data synchronized with the streams;
- Receive Now Playing History information; and
- Advertising:
    - Sync banners
    - On-demand audio and video interstitial ads
    - Support for VAST and DAAST formats

For complete documentation on using the Triton Digital® Mobile SDK for iOS, visit our [online documentation](https://userguides.tritondigital.com/spc/mobios/).

## Getting Started

The following instructions will get a copy of the project up and running on your local machine for development and testing purposes. 

## Prerequisites

&ensp; XCode (via App Store)<br>
&ensp; Git Client (via App Store)<br>
&ensp; [Brew](https://brew.sh/)<br>
&ensp; Appledoc (via Brew)<br>

In order to link the Triton Digital® Mobile SDK for iOS, the frameworks SystemConfiguration, AdSupport, AVFoundation, MediaPlayer and CoreMedia must also be linked in Xcode.

In order to install and use the Triton Digital® Mobile SDK for iOS you may be required to download proprietary third party libraries. You are responsible to ensure that you have all the necessary right and authorizations to download and install such libraries and that you comply with the applicable license.

### Installing

Install Xcode from the App Store
Fork and clone the ios-sdk project on git

In your terminal run this command from the folder where you forked the SDK:
```bash
sh xcode_build.sh <version number>
```

This will create a folder (e.g. triton-ios-sdk-2.7) containing the sample application which you can open and run in XCode.

## Running the tests

- Open the SDK source code in XCode<br>
- Select the TritonPlayerSDKStatic target<br>
- Open the Product menu item and select Test<br>

## Built With

[Xcode](https://developer.apple.com/xcode/)

## Contributing

If you wish to contribute to this project, please see the [CONTRIBUTING.md](CONTRIBUTING.md) file for details.

## Versioning

We use an internal versioning system. All accepted contributions will be versioned under this versioning scheme.

## License

This project is licensed under the Apache 2.0 License - see the [LICENSE.md](LICENSE.md) file for details

