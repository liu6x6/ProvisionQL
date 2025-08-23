# ProvisionQL - Quick Look for ipa & provision

[![Build Status](https://github.com/ealeksandrov/ProvisionQL/workflows/build/badge.svg?branch=main)](https://github.com/ealeksandrov/ProvisionQL/actions)
[![Latest Release](https://img.shields.io/github/release/ealeksandrov/ProvisionQL.svg)](https://github.com/ealeksandrov/ProvisionQL/releases/latest)
[![License](https://img.shields.io/github/license/ealeksandrov/ProvisionQL.svg)](LICENSE.md)
![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)

Inspired by a number of existing alternatives, the goal of this project is to provide clean, reliable, current and open source Quick Look plugin for iOS & macOS developers.

Thumbnails will show app icon for `.ipa`/ `.xcarchive` or expiring status and device count for `.mobileprovision`. Quick Look preview will give a lot of information, including devices UUIDs, certificates, entitlements and much more.

Supported file types:

* `.ipa` - iOS packaged application
* `.xcarchive` - Xcode archive
* `.appex` - iOS/OSX application extension
* `.mobileprovision` - iOS provisioning profile
* `.provisionprofile` - OSX provisioning profile

## Installation

### Manual

* download archive with latest version from the [Releases](https://github.com/ealeksandrov/ProvisionQL/releases/latest) page;
* unzip;
* move to `Applications/`;
* run ProvisionQL app once;
* enable extensions in System Settings > Login Items & Extensions > Quick Look.

## Author

Created and maintained by Evgeny Aleksandrov ([@ealeksandrov](https://twitter.com/ealeksandrov)).

### Acknowledgments

Initially based on [Provisioning by Craig Hockenberry](https://github.com/chockenberry/Provisioning).

## License

`ProvisionQL` is available under the MIT license. See the [LICENSE.md](LICENSE.md) file for more info.
