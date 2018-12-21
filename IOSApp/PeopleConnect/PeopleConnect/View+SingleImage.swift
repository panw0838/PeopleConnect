//
//  View+SingleImage.swift
//  PeopleConnect
//
//  Created by apple on 18/12/19.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit
import Photos

class SingleImgView:UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var m_scrView: UIScrollView!
    
    var m_imgView = UIImageView()
    var m_asset:PHAsset? = nil
    var m_image:UIImage? = nil
    
    init (asset:PHAsset) {
        super.init(nibName: "SingleImg", bundle: NSBundle(forClass: ImgPicker.classForCoder()))
        m_asset = asset
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @IBAction func clipPhoto(sender: AnyObject) {
        let offset = m_scrView.contentOffset
        //图片缩放比例
        var zoom = m_imgView.frame.size.width / m_image!.size.width;
        //视网膜屏幕倍数相关
        zoom = zoom / UIScreen.mainScreen().scale;
        
        let width = m_scrView.frame.size.width
        let height = m_scrView.frame.size.height
        /*
        if m_imgView.frame.size.height < _scrollView.frame.size.height) {//太胖了,取中间部分
            offset = CGPointMake(offset.x + (width - _imageView.frame.size.height)/2.0, 0);
            width = height = _imageView.frame.size.height;
        }
        */
        let rec = CGRectMake(offset.x/zoom, offset.y/zoom, width/zoom, height/zoom);
        
        let imageRef = CGImageCreateWithImageInRect(m_image?.CGImage,rec)
        let newImg = UIImage(CGImage: imageRef!)

        /*
        if (_ovalClip) {
            image = [image ovalClip];
        }
        */
        //self.m_delegate?.didClippedPickImage(image)
    }
    
    @IBAction func cancel(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cancelBtn = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: Selector("cancel:"))
        self.navigationItem.leftBarButtonItem = cancelBtn
        
        let clipBtn = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: Selector("clipPhoto:"))
        self.navigationItem.rightBarButtonItem = clipBtn
        
        let scale = UIScreen.mainScreen().scale
        let width = CGRectGetWidth(UIScreen.mainScreen().bounds)
        let height = CGRectGetHeight(UIScreen.mainScreen().bounds) - CGRectGetHeight((navigationController?.navigationBar.bounds)!)
        let tarSize = CGSizeMake(width*scale*scale, height*scale*scale)
        let space = (height - width) / 2
        
        m_imgView.frame = CGRectZero
        m_scrView.addSubview(m_imgView)
        m_scrView.contentInset = UIEdgeInsets(top: space, left: 0, bottom: space, right: 0)
        
        PHCachingImageManager().requestImageForAsset(m_asset!, targetSize: tarSize, contentMode: .AspectFit, options: nil, resultHandler: {(result:UIImage?, info:[NSObject:AnyObject]?)->Void in
            self.m_imgView.image = result
            self.m_image = result
            
            var baseWidth:CGFloat = 0
            var baseHeight:CGFloat = 0
            var baseScale:CGFloat = 1
            
            if result?.size.width > result?.size.height {
                baseScale = (result?.size.height)! / width
                baseWidth = (result?.size.width)! / baseScale
                baseHeight = width
            }
            else {
                baseScale = (result?.size.width)! / width
                baseWidth = width
                baseHeight = (result?.size.height)! / baseScale
            }
            
            self.m_imgView.frame.size = CGSizeMake(baseWidth, baseHeight)
            self.m_scrView.contentSize = CGSizeMake(baseWidth, baseHeight)
            
            print(result?.size.width, result?.size.height)
            self.m_imgView.contentMode = .ScaleToFill
            //self.m_imgView.clipsToBounds = true
            //self.m_imgView.contentScaleFactor = scale
            
            //m_scrView.frame = CGRectMake(0, 0, width, heigt)
            self.m_scrView.bouncesZoom = false
            self.m_scrView.minimumZoomScale = 1
            self.m_scrView.maximumZoomScale = baseScale
            self.m_scrView.zoomScale = 1
            self.m_scrView.delegate = self
            self.m_scrView.layer.masksToBounds = true
            self.m_scrView.showsHorizontalScrollIndicator = true
            self.m_scrView.showsVerticalScrollIndicator = true
            self.m_scrView.layer.borderWidth = 1.5
            self.m_scrView.layer.borderColor = UIColor.whiteColor().CGColor
        })
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        //m_imgView.frame.size = (m_image?.size)!
        return m_imgView
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
    }
}
