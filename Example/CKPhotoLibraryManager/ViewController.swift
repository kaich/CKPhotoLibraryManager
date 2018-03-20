//
//  ViewController.swift
//  CKPhotoLibraryManager
//
//  Created by kaich on 11/02/2016.
//  Copyright (c) 2016 kaich. All rights reserved.
//

import UIKit
import CKPhotoLibraryManager

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        CKPhotoLibraryManager.shared.didFindPermissionTrouble = { status in
            let alert = UIAlertController(title: "", message: "请在iPhone的“设置-爱思助手-隐私-照片”选项中，允许爱思助手访问您照片。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "暂不设置", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "现在设置", style: .default, handler: { _ in
                UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func importAlbum(_ sender: AnyObject) {
        if let filePath = Bundle.main.path(forResource: "map", ofType: "png") {
            CKPhotoLibraryManager.shared.addAsset(filePath: filePath, type: .image, albumName: "CKPhoto") { (isOK, path, error) in
                if error == nil {
                    let alert = UIAlertController(title: "导入成功", message: nil, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "确定", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    
    @IBAction func importPhotoAlbum(_ sender: Any) {
        if let filePath = Bundle.main.path(forResource: "map", ofType: "png") {
            CKPhotoLibraryManager.shared.addAsset(filePath: filePath, type: .image) { (isOK, path, error) in
                if error == nil {
                    let alert = UIAlertController(title: "导入成功", message: nil, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "确定", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    
    @IBAction func deletePhotoAlbum(_ sender: Any) {
        CKPhotoLibraryManager.shared.deleteAlbum(title: "CKPhoto", isDeleteAssets: true) { (error) in
            if error == nil {
                let alert = UIAlertController(title: "删除成功", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "确定", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func importLivePhoto(_ sender: Any) {
        if let filePath = Bundle.main.path(forResource: "IMG_0350", ofType: "JPG"), let filePath2 = Bundle.main.path(forResource: "IMG_0350", ofType: "MOV") {
            CKPhotoLibraryManager.shared.addAsset(filePath: filePath,  filePath2: filePath2, type: .livePhoto) { (isOK, path, error) in
                if error == nil {
                    let alert = UIAlertController(title: "导入成功", message: nil, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "确定", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
}

