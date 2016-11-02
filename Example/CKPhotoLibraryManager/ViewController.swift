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
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func importAlbum(_ sender: AnyObject) {
        if let filePath = Bundle.main.path(forResource: "map", ofType: "png") {
            CKPhotoLibraryManager.shared.addAssert(filePath: filePath, type: .image, albumName: "CKPhoto") { (isOK, path, error) in
                if error == nil {
                    let alert = UIAlertController(title: "导入成功", message: nil, preferredStyle: .alert)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
}

