//
//  ContactView.swift
//  PeopleConnect
//
//  Created by apple on 18/11/17.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit


class ContactView: PostsTable, UITableViewDelegate, DetailDelegate {
    
    @IBOutlet weak var m_name: UILabel!
    @IBOutlet weak var m_profile: UIImageView!
    @IBOutlet weak var m_background: UIImageView!
    @IBOutlet weak var m_posts: UITableView!
    @IBOutlet weak var m_likeBtn: UIButton!
    
    static var ContactID:UInt64 = 0
    static var Detail = DetailData()
    
    var m_preDelegate:PostDataDelegate?
    
    @IBAction func likeUser(sender:AnyObject) {
        if !m_likeBtn.selected {
            httpLikeUser(ContactView.ContactID, like: true, btn: m_likeBtn)
        }
    }
    
    func DetailUpdate() {
        m_likeBtn.selected = ContactView.Detail.m_detail!.like
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        m_likeBtn.setImage(UIImage(named: "post_like"), forState: .Normal)
        m_likeBtn.setImage(UIImage(named: "post_like_hi"), forState: .Selected)
        
        let user = contactsData.getUser(ContactView.ContactID)
        m_likeBtn.hidden = (user?.flag != 0)
        
        ContactView.Detail.m_delegate = self
        httpGetUserDetails(ContactView.ContactID)
        
        m_profile.layer.cornerRadius = 10
        
        m_name.text = getName(ContactView.ContactID)
        m_profile.image = getPhoto(ContactView.ContactID)

        if getContactPhoto(ContactView.ContactID) == nil {
            let cIDs:Array<UInt64> = [ContactView.ContactID]
            httpGetPhotos(cIDs,
                passed: {()->Void in
                    self.m_profile.image = getPhoto(ContactView.ContactID)
                },
                failed: nil)
        }

        var postData:PostData?
        
        if ContactView.ContactID == userInfo.userID {
            postData = selfPosts
        }
        else {
            postData = getContactPost(ContactView.ContactID)
        }
        
        m_preDelegate = postData?.m_delegate
        setTable(m_posts, data: postData!, showPhoto: false, showMsg: false)
        postData?.Update()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        m_data?.setDelegate(m_preDelegate)
        ContactView.ContactID = 0
    }
}

