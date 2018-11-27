//
//  View+CreatePost.swift
//  PeopleConnect
//
//  Created by apple on 18/11/27.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

class AttachmentCell:UICollectionViewCell {
    @IBOutlet weak var m_preview: UIImageView!
    
}

class CreatePostView:UITableViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    
    @IBOutlet weak var m_desc: UITextField!
    @IBOutlet weak var m_allowed: UISegmentedControl!
    
    
    @IBAction func CreatePost(sender: AnyObject) {
    }
    
    var m_picker:UIImagePickerController = UIImagePickerController()
    var m_atts:Array<String> = Array<String>()
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return m_atts.count + 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("AttachmentCell", forIndexPath: indexPath) as! AttachmentCell
        if indexPath.row < m_atts.count {
            
        }
        else {
            cell.m_preview.image = UIImage(named: "plus")
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row < m_atts.count {
            
        }
        else {
            m_picker.sourceType = .SavedPhotosAlbum
            self.presentViewController(m_picker, animated: true) {() -> Void in}
        }
    }

}
