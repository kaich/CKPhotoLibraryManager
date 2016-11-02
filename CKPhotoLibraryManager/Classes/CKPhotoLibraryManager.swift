//
//  CKPhotoLibraryManager.swift
//  AwesomeBat
//
//  Created by mac on 16/10/27.
//  Copyright © 2016年 kaicheng. All rights reserved.
//

import UIKit
import Photos

public enum CKPhotoType {
    case image, video
}

public class CKPhotoLibraryManager: NSObject {
    
    public static let shared = CKPhotoLibraryManager()
    
    
    /// 提示授权
    ///
    /// - parameter successfulBlock: 如果授权成功执行回调
    public func authorize(successfulBlock :((Void) -> Void)?) {
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            PHPhotoLibrary.requestAuthorization({ (status) in
                if let successfulBlock = successfulBlock {
                    successfulBlock()
                }
            })
        }
        else {
            if let successfulBlock = successfulBlock {
                successfulBlock()
            }
        }
    }
    

    var isAlbumCreateComplete = true
    
    /// 添加指定名称的相册
    ///
    /// - parameter title:         相册名称
    /// - parameter completeBlock: 完成回调
    public func addAlbum(title :String, completeBlock :((String) -> Void)?) {
        authorize {
        self.isAlbumCreateComplete = false
            
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", title)
        let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        if let album = albums.firstObject {
            if let completeBlock = completeBlock {
                completeBlock(album.localIdentifier)
            }
            self.isAlbumCreateComplete = true
            
            return
        }
        
        var album :PHObjectPlaceholder? = nil
        PHPhotoLibrary.shared().performChanges({
            let creatingRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
            album = creatingRequest.placeholderForCreatedAssetCollection
        }) { (isFinish, error) in
            if isFinish == true && error == nil {
                if let completeBlock = completeBlock {
                    completeBlock((album?.localIdentifier)!)
                }
            }
            self.isAlbumCreateComplete = true
        }
            
            
        while self.isAlbumCreateComplete == false {
            RunLoop.current.run(mode: .defaultRunLoopMode , before: Date.distantFuture)
        }
            
        }
    }
    
    
    /// 添加图片或者视频到指定相册
    ///
    /// - parameter url:           图片或者视频url
    /// - parameter type:          图片或者视频
    /// - parameter album:         相册
    /// - parameter completeBlock: 完成回调
    public func addAsset(url: URL, type :CKPhotoType, to album: PHAssetCollection, completeBlock :((Bool,URL,Error?) -> Void)?) {
        authorize {
        
        PHPhotoLibrary.shared().performChanges({
            var creationRequest :PHAssetChangeRequest? = nil
            if type == .image {
                creationRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
            }
            else if type == .video {
                creationRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }

            guard let addAssetRequest = PHAssetCollectionChangeRequest(for: album)
                else { return }
            guard let placeholder = creationRequest?.placeholderForCreatedAsset else {
                return
            }
            addAssetRequest.addAssets([placeholder] as NSArray)
            }, completionHandler: { success, error in
                if !success { NSLog("error creating asset: \(error)") }
                if let completeBlock = completeBlock {
                    completeBlock(success, url , error)
                }
        })
            
        }
    }
    
    
    /// 添加图片或者视频到指定相册，如果没有该相册就创建
    ///
    /// - parameter filePath:      视频或者图片路径
    /// - parameter type:          视频或图片
    /// - parameter albumName:     相册名称
    /// - parameter completeBlock: 完成回调
    public func addAssert(filePath :String, type :CKPhotoType, albumName :String, completeBlock :((Bool,String,Error?) -> Void)?) {
        authorize {
        
        let url  = URL(fileURLWithPath: filePath)
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        if let album = albums.firstObject {
            self.addAsset(url: url, type: type , to: album, completeBlock: { (isOK, url, error) in
                if let completeBlock = completeBlock {
                   completeBlock(isOK, filePath, error)
                }
            })
        }
        else {
           self.addAlbum(title: albumName, completeBlock: { (identifier) in
                let albums = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [identifier], options: nil)
                if let album = albums.firstObject {
                    self.addAsset(url: url, type: type, to: album, completeBlock: { (isOK, image, error) in
                        if let completeBlock = completeBlock {
                           completeBlock(isOK, filePath, error)
                        }
                    })
                }
           })
        }
            
            
        }
    }
    
}
