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

class CreatePostView:UITableViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    @IBOutlet weak var m_attachments: UICollectionView!
    @IBOutlet weak var m_desc: UITextField!
    @IBOutlet weak var m_allowed: UISegmentedControl!
    
    
    @IBAction func CreatePost(sender: AnyObject) {
        let desc = m_desc.text
        var datas = Array<NSData>()
        for image in m_atts {
            let data = UIImagePNGRepresentation(image)
            datas.append(data!)
        }
        httpSendPost(0, desc: desc!, datas: datas)
    }
    
    var m_picker:UIImagePickerController = UIImagePickerController()
    var m_atts:Array<UIImage> = Array<UIImage>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        m_picker.delegate = self
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        m_atts.append(image)
        m_attachments.reloadData()
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return m_atts.count + 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("AttachmentCell", forIndexPath: indexPath) as! AttachmentCell
        if indexPath.row < m_atts.count {
            cell.m_preview.image = m_atts[indexPath.row]
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
