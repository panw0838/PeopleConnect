//
//  View+SingleImage.swift
//  PeopleConnect
//
//  Created by apple on 18/12/19.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit
import Photos

class SingleImgView:UIViewController {
    
    @IBOutlet weak var m_imgView: UIImageView!
    
    var m_asset:PHAsset? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scale = UIScreen.mainScreen().scale
        let width = CGRectGetWidth(UIScreen.mainScreen().bounds) * scale
        let height = (CGRectGetHeight(UIScreen.mainScreen().bounds) - CGRectGetHeight((navigationController?.navigationBar.bounds)!)) * scale
        let imgSize = CGSizeMake(width, height)
        let tarSize = CGSizeMake(imgSize.width*scale, imgSize.height*scale)
        
        PHCachingImageManager().requestImageForAsset(m_asset!, targetSize: tarSize, contentMode: .AspectFill, options: nil, resultHandler: {(result:UIImage?, info:[NSObject:AnyObject]?)->Void in
            self.m_imgView.image = result
        })
    }
}
