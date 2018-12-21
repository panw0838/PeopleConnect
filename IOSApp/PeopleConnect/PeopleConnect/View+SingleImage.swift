//
//  View+SingleImage.swift
//  PeopleConnect
//
//  Created by apple on 18/12/19.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit
import Photos

protocol PhotoClipperDelegate {
    func didClippedPickImage(img:UIImage)
}

class SingleImgView:UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var m_scrView: UIScrollView!
    
    var m_imgView = UIImageView()
    var m_asset:PHAsset? = nil
    var m_image:UIImage? = nil
    var m_delegate:PhotoClipperDelegate? = nil
    
    init (asset:PHAsset) {
        super.init(nibName: "SingleImg", bundle: NSBundle(forClass: ImgPicker.classForCoder()))
        m_asset = asset
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @IBAction func clipPhoto(sender: AnyObject) {
        let width = CGRectGetWidth(UIScreen.mainScreen().bounds)
        let height = CGRectGetHeight(UIScreen.mainScreen().bounds)
        let space = (height - width) / 2
        let size = m_scrView.frame.size.width
        let x = m_scrView.contentOffset.x
        let y = m_scrView.contentOffset.y + space
        let scale = (m_scrView.maximumZoomScale / m_scrView.zoomScale)
        let rect = CGRectMake(x*scale, y*scale, size*scale, size*scale)

        let imageRef = CGImageCreateWithImageInRect(m_image?.CGImage, rect)
        let newImg = UIImage(CGImage: imageRef!)
        let finalImg = resizeImage(newImg, newSize: CGSizeMake(50, 50))

        self.m_delegate?.didClippedPickImage(finalImg)
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
        let height = CGRectGetHeight(UIScreen.mainScreen().bounds)// - naviHeight
        let tarSize = CGSizeMake(width*scale*scale, height*scale*scale)
        let space = (height - width) / 2
        
        m_imgView.frame = CGRectZero
        //m_scrView.frame = CGRectMake(0, naviHeight, width, height)
        m_scrView.addSubview(m_imgView)
        let naviHeight = CGRectGetHeight((navigationController?.navigationBar.bounds)!)
        let statusHeight = UIApplication.sharedApplication().statusBarFrame.height
        m_scrView.contentInset = UIEdgeInsets(top: space-naviHeight-statusHeight, left: 0, bottom: space, right: 0)
        
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
