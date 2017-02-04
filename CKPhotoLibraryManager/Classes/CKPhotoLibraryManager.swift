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
    public var didFindPermissionTrouble: ((PHAuthorizationStatus) -> Swift.Void)?
    
    /// 提示授权
    ///
    /// - parameter successfulBlock: 如果授权成功执行回调
    public func authorize(successfulBlock :((Void) -> Void)?) {
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            PHPhotoLibrary.requestAuthorization({ (status) in
                if status == .authorized {
                    if let successfulBlock = successfulBlock {
                        successfulBlock()
                    }
                }
                else {
                    if let didFindPermissionTrouble = self.didFindPermissionTrouble {
                        didFindPermissionTrouble(status)
                    }
                }
            })
        }
        else {
            if let successfulBlock = successfulBlock {
                successfulBlock()
            }
        }
    }
    

    /// 添加指定名称的相册
    ///
    /// - parameter title:         相册名称
    /// - parameter completeBlock: 完成回调
    public func addAlbum(title :String, completeBlock :((String) -> Void)?) {
        authorize {
        var albumCreateSemaphore = DispatchSemaphore(value: 0)
            
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", title)
        let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        if let album = albums.firstObject {
            if let completeBlock = completeBlock {
                completeBlock(album.localIdentifier)
            }
            
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
            
            albumCreateSemaphore.signal()
        }
            
            
            albumCreateSemaphore.wait()
        }
    }
    
    
    /// 获取相册
    ///
    /// - Parameters:
    ///   - type: 类型
    ///   - subType: 子类型
    ///   - options: 条件
    /// - Returns:  符合条件的相册
    public func fetchAlbums(type :PHAssetCollectionType, subType :PHAssetCollectionSubtype, options :PHFetchOptions? = nil) -> PHFetchResult<PHAssetCollection> {
        let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
        return albums
    }
    
    
    /// 获取相册
    ///
    /// - Parameters:
    ///   - type: 类型
    ///   - subType: 子类型
    ///   - predicate: 筛选条件
    /// - Returns: 符合条件的相册
    public func fetchAlbums(type :PHAssetCollectionType, subType :PHAssetCollectionSubtype, predicate :NSPredicate?) -> PHFetchResult<PHAssetCollection> {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = predicate
        let albums = fetchAlbums(type: type, subType: subType, options: fetchOptions)
        return albums
    }
    
    
    /// 获取相册
    ///
    /// - Parameters:
    ///   - type: 类型
    ///   - subType: 子类型
    ///   - albumName: 相册名称
    /// - Returns: 符合条件的相册
    public func fetchAlbums(type :PHAssetCollectionType = .album, subType :PHAssetCollectionSubtype = .any, albumName :String) -> PHFetchResult<PHAssetCollection> {
        let predicate = NSPredicate(format: "title = %@", albumName)
        return fetchAlbums(type: type, subType: subType, predicate: predicate)
    }
    
    
    /// 添加图片或者视频到指定相册
    ///
    /// - parameter url:           图片或者视频url
    /// - parameter type:          图片或者视频
    /// - parameter album:         相册
    /// - parameter completeBlock: 完成回调
    public func addAsset(url: URL, type :CKPhotoType, to album: PHAssetCollection?, completeBlock :((Bool,URL,Error?) -> Void)?) {
        authorize {
        
        PHPhotoLibrary.shared().performChanges({
            var creationRequest :PHAssetChangeRequest? = nil
            if type == .image {
                creationRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
            }
            else if type == .video {
                creationRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }

            if let album = album {
                guard let addAssetRequest = PHAssetCollectionChangeRequest(for: album)
                    else { return }
                guard let placeholder = creationRequest?.placeholderForCreatedAsset else {
                    return
                }
                addAssetRequest.addAssets([placeholder] as NSArray)
            }
            
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
    public func addAsset(filePath :String, type :CKPhotoType, albumName :String, completeBlock :((Bool,String,Error?) -> Void)?) {
        authorize {
        
        let url  = URL(fileURLWithPath: filePath)
        let albums = self.fetchAlbums(albumName: albumName)
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
    
    
    /// 添加图片或者视频到相机胶卷
    ///
    /// - Parameters:
    ///   - filePath: 视频或者图片路径
    ///   - type:          视频或图片
    ///   - completeBlock: 完成回调
    public func addAsset(filePath :String, type :CKPhotoType, completeBlock :((Bool,String,Error?) -> Void)?) {
        let url  = URL(fileURLWithPath: filePath)
        addAsset(url: url, type: type, to: nil, completeBlock: { (isOK, url, error) in
            if let completeBlock = completeBlock {
                completeBlock(isOK,filePath,error)
            }
        })
    }
    
    
    
}
