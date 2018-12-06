//
//  View+ImagePicker.swift
//  PeopleConnect
//
//  Created by apple on 18/12/5.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit
import Photos

class ImgCell:UICollectionViewCell {
    @IBOutlet weak var m_img: UIImageView!
    @IBOutlet weak var m_select: UIButton!
}

class MulImgPicker: UIImagePickerController, UICollectionViewDataSource, UICollectionViewDelegate {
    var m_imgs = Array<UIImage>()
    var m_selectImgs = Set<UIImage>()
    let m_maxCount = 9
    var m_collectionItem = NSMutableDictionary()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let targetClass = NSClassFromString("PUPhotosGridViewController")
        
    }
    
    override func viewDidLoad() {
        
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return m_imgs.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ImgCell", forIndexPath: indexPath) as! ImgCell
        cell.m_img.image = m_imgs[indexPath.row]
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ImgCell
        cell.m_select.hidden = true
        m_selectImgs.remove(m_imgs[indexPath.row])
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ImgCell
        cell.m_select.hidden = false
        m_selectImgs.insert(m_imgs[indexPath.row])
    }
}