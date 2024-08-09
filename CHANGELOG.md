## 0.3.10

* Fix isDebug environment for multiple non RELEASE build configs https://github.com/aptabase/aptabase-swift/pull/24

## 0.3.9

* Fix device model for Mac https://github.com/aptabase/aptabase-swift/pull/22
* Fix application hang/crash https://github.com/aptabase/aptabase-swift/pull/19

## 0.3.8

* Add `deviceModel`

## 0.3.7

* Add support for visionOS

## 0.3.6

* Fix bad formatting in podspec

## 0.3.5

* Only include .h, .m, .swift files in the podspec

## 0.3.4

* Use new session id format

## 0.3.3

* Added Privacy Manifest (PrivacyInfo.xcprivacy)

## 0.3.2

* Dropped support for Swift 5.6
* Added automated tests for Xcode 14+

## 0.3.1

* Restore support for watchOS 7+

## 0.3.0

* Migrated to new event batching and background flush for tracking, the result is lower resource usage and better support for offline events.
* Refactor Xcode project and examples

## 0.2.3

* support for macOS Catalyst (thanks @manucheri)

## 0.2.2

* Fix compile issues on Swift 5.6 (thanks @manucheri)

## 0.2.1

* Added DocC support (thanks @manucheri)

## 0.2.0

* Added support for ObjC

## 0.1.0

* General refactor
* Explicitly define what types are allowed for custom properties

## 0.0.7

* Added support for CocoaPods

## 0.0.6

* Added support for automatic segregation of Debug/Release data source

## 0.0.5

* Ability to set custom hosts for self hosted servers

## 0.0.4

* Updated to new API endpoints

## 0.0.3

* Moved from static functions to the 'shared' singleton pattern.
