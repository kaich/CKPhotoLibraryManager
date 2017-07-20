# CKPhotoLibraryManager

[![CI Status](http://img.shields.io/travis/kaich/CKPhotoLibraryManager.svg?style=flat)](https://travis-ci.org/kaich/CKPhotoLibraryManager)
[![Version](https://img.shields.io/cocoapods/v/CKPhotoLibraryManager.svg?style=flat)](http://cocoapods.org/pods/CKPhotoLibraryManager)
[![License](https://img.shields.io/cocoapods/l/CKPhotoLibraryManager.svg?style=flat)](http://cocoapods.org/pods/CKPhotoLibraryManager)
[![Platform](https://img.shields.io/cocoapods/p/CKPhotoLibraryManager.svg?style=flat)](http://cocoapods.org/pods/CKPhotoLibraryManager)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

CKPhotoLibraryManager is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "CKPhotoLibraryManager"
```

## Usage 

Simple to use:

```swift
CKPhotoLibraryManager.shared.addAsset(filePath: filePath, type: .image, albumName: "CKPhoto") { (isOK, path, error) in
                if error == nil {
                    let alert = UIAlertController(title: "导入成功", message: nil, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "确定", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
```

## Author

kaich, chengkai1853@163.com

## License

CKPhotoLibraryManager is available under the MIT license. See the LICENSE file for more info.
