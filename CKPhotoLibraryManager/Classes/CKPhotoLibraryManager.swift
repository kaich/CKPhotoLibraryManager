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
    case image, video, livePhoto
}

public enum CKPhotoAccessLevel: Int {
    case addOnly = 1
    case readWrite = 2
    
    @available(iOS 14, *)
    var level: PHAccessLevel {
        return PHAccessLevel(rawValue: rawValue)!
    }
}

public class CKPhotoLibraryManager: NSObject {
    
    public static let shared = CKPhotoLibraryManager()
    public var didFindPermissionTrouble: ((PHAuthorizationStatus) -> Swift.Void)?
    
    /// 提示授权
    ///
    /// - parameter successfulBlock: 如果授权成功执行回调
    public func authorize(for level: CKPhotoAccessLevel = .readWrite, successfulBlock :(() -> ())?) {
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            let handleTask = { (status: PHAuthorizationStatus) in
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
            }
            if #available(iOS 14, *) {
                PHPhotoLibrary.requestAuthorization(for: level.level) { (status) in
                    handleTask(status)
                }
            } else {
                PHPhotoLibrary.requestAuthorization({ (status) in
                    handleTask(status)
                })
            }

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
    public func addAlbum(title :String, completeBlock :((String,Error?) -> Void)?) {
        authorize {
        let albumCreateSemaphore = DispatchSemaphore(value: 0)
            
        let albums = self.fetchAlbums(type: .album, subType: .any, albumName: title)
        if let album = albums.firstObject {
            if let completeBlock = completeBlock {
                completeBlock(album.localIdentifier,nil)
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
                    completeBlock((album?.localIdentifier)!,nil)
                }
            }
            else {
                if let completeBlock = completeBlock {
                    completeBlock((album?.localIdentifier)!,error)
                }
            }
            
            albumCreateSemaphore.signal()
        }
            
            
            albumCreateSemaphore.wait()
        }
    }
    

    /// 删除相册
    ///
    /// - Parameters:
    ///   - title: 名称
    ///   - completeBlock: 完成回调
    public func deleteAlbum(title :String, isDeleteAssets :Bool = false, completeBlock :((Error?) -> Void)?) {
        authorize {
            
            let albums = self.fetchAlbums(type: .album, subType: .any, albumName: title)
            guard let _ = albums.firstObject else {
                if let completeBlock = completeBlock {
                    let error = NSError(domain: "Album don't exist!", code: 302, userInfo: nil)
                    completeBlock(error)
                }
                
                return
            }
            
            self.deleteAlbums(albums, isDeleteAssets: isDeleteAssets, completeBlock: completeBlock)
        }
    }
    
    
    /// 删除相册
    ///
    /// - Parameters:
    ///   - albums: 相册
    ///   - isDeleteAssets: 是否删除相册里面的文件
    ///   - completeBlock: 完成回调  error为nil时成功，否则失败
    public func deleteAlbums(_ albums :PHFetchResult<PHAssetCollection>, isDeleteAssets :Bool = false, completeBlock :((Error?) -> Void)?) {
        authorize {
        var isReadyDeleteAlbum = true
        if isDeleteAssets {
            let albumDeleteSemaphore = DispatchSemaphore(value: 0)
            for i in 0...(albums.count - 1) {
                let album = albums.object(at: i)
                if let assets = self.fetchAssetsInAlbum(album: album) {
                    self.deleteAssets(assets: assets, completeBlock: { (error) in
                        if let error = error {
                            if let completeBlock = completeBlock {
                                completeBlock(error)
                            }
                            isReadyDeleteAlbum = false
                            
                            albumDeleteSemaphore.signal()
                            return 
                        }
                        
                        if i == albums.count - 1 {
                            albumDeleteSemaphore.signal()
                        }
                    })
                }
            }
            
            albumDeleteSemaphore.wait()
        }
            
        if isReadyDeleteAlbum {
            PHPhotoLibrary.shared().performChanges({
                PHAssetCollectionChangeRequest.deleteAssetCollections(albums)
            }) { (isFinish, error) in
                if isFinish == true && error == nil {
                    if let completeBlock = completeBlock {
                        completeBlock(nil)
                    }
                }
                else {
                    if let completeBlock = completeBlock {
                        completeBlock(error)
                    }
                }
                
            }
        }
        
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
        let albums = PHAssetCollection.fetchAssetCollections(with: type, subtype: subType, options: options)
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
    /// - parameter url2:          LivePhoto视频地址,只有livePhoto才用到
    /// - parameter type:          图片或者视频
    /// - parameter album:         相册
    /// - parameter completeBlock: 完成回调
    public func addAsset(url: URL, url2: URL? = nil, type :CKPhotoType, to album: PHAssetCollection?, completeBlock :((Bool,URL,Error?) -> Void)?) {
        
        if type == .livePhoto {
            guard #available(iOS 9.1, *) else {
                if let completeBlock = completeBlock {
                    completeBlock(false, url, NSError(domain: "IOS 9.1 available", code: -100, userInfo: nil))
                }
                return
            }
            
            guard url2 != nil else {
                if let completeBlock = completeBlock {
                    completeBlock(false, url, NSError(domain: "url2 can't be nil for live photo", code: -101, userInfo: nil))
                }
                return
            }
            
        }
        
        authorize {
        
        PHPhotoLibrary.shared().performChanges({
            var placeholder: PHObjectPlaceholder?
            var creationRequest :PHAssetChangeRequest? = nil
            if type == .livePhoto {

                if #available(iOS 9.1, *) {
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .photo, fileURL: url, options: nil)
                    creationRequest.addResource(with: .pairedVideo, fileURL: url2!, options: nil)
                    
                    placeholder = creationRequest.placeholderForCreatedAsset
                }
            }
            else {
                if type == .image {
                    creationRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
                }
                else if type == .video {
                    creationRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }
                
                placeholder = creationRequest?.placeholderForCreatedAsset
            }

            if let album = album {
                guard let addAssetRequest = PHAssetCollectionChangeRequest(for: album)
                    else { return }
                guard let placeholder = placeholder else {
                    return
                }
                addAssetRequest.addAssets([placeholder] as NSArray)
            }
            
            }, completionHandler: { success, error in
                if !success { NSLog("error creating asset: \(String(describing: error))") }
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
    public func addAsset(filePath :String, filePath2: String? = nil, type :CKPhotoType, albumName :String, completeBlock :((Bool,String,Error?) -> Void)?) {
        authorize {
        
        let url  = URL(fileURLWithPath: filePath)
        let url2  = filePath2 == nil ? nil : URL(fileURLWithPath: filePath2!)
        let albums = self.fetchAlbums(albumName: albumName)
        if let album = albums.firstObject {
            self.addAsset(url: url, url2: url2, type: type , to: album, completeBlock: { (isOK, url, error) in
                if let completeBlock = completeBlock {
                   completeBlock(isOK, filePath, error)
                }
            })
        }
        else {
           self.addAlbum(title: albumName, completeBlock: { (identifier, error) in
                let albums = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [identifier], options: nil)
                if let album = albums.firstObject {
                    self.addAsset(url: url, url2: url2, type: type, to: album, completeBlock: { (isOK, image, error) in
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
    public func addAsset(filePath :String, filePath2: String? = nil, type :CKPhotoType, completeBlock :((Bool,String,Error?) -> Void)?) {
        let url  = URL(fileURLWithPath: filePath)
        let url2  = filePath2 == nil ? nil : URL(fileURLWithPath: filePath2!)
        addAsset(url: url, url2: url2, type: type, to: nil, completeBlock: { (isOK, url, error) in
            if let completeBlock = completeBlock {
                completeBlock(isOK,filePath,error)
            }
        })
    }
    
    
    /// 删除资源
    ///
    /// - Parameters:
    ///   - assets: 视频或者图片
    ///   - completeBlock: 完成回调
    public func deleteAssets(assets :PHFetchResult<PHAsset>, completeBlock :((Error?) -> Void)?) {
        authorize {
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(assets)
            }) { (isFinish, error) in
                if isFinish == true && error == nil {
                    if let completeBlock = completeBlock {
                        completeBlock(nil)
                    }
                }
                else {
                    if let completeBlock = completeBlock {
                        completeBlock(error)
                    }
                }
                
            }
            
        }
    }
   
    
    /// 指定相册查找资源
    ///
    /// - Parameters:
    ///   - albumName: 相册名称
    ///   - options: 选项
    /// - Returns: 查询结果
    public func fetchAssetsInAlbum(albumName :String, options: PHFetchOptions? = nil) -> PHFetchResult<PHAsset>? {
        let albums = fetchAlbums(albumName: albumName)
        if let album = albums.firstObject {
            return fetchAssetsInAlbum(album: album)
        }
        return nil
    }
    
    
    /// 指定相册查找资源
    ///
    /// - Parameters:
    ///   - album: 相册
    ///   - options: 选项
    /// - Returns: 查询结果
    public func fetchAssetsInAlbum(album :PHAssetCollection, options: PHFetchOptions? = nil) -> PHFetchResult<PHAsset>? {
        return PHAsset.fetchAssets(in: album, options: options)
    }
    
}
