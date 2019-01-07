//
//  ContactView.swift
//  PeopleConnect
//
//  Created by apple on 18/11/17.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit


class ContactView: PostsTable, UITableViewDelegate {
    
    @IBOutlet weak var m_name: UILabel!
    @IBOutlet weak var m_profile: UIImageView!
    @IBOutlet weak var m_background: UIImageView!
    @IBOutlet weak var m_posts: UITableView!
    
    static var ContactID:UInt64 = 0
    
    var m_preDelegate:PostDataDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            if contactsPosts[ContactView.ContactID] == nil {
                postData = PostData(cid: ContactView.ContactID)
                contactsPosts[ContactView.ContactID] = postData
            }
            else {
                postData = contactsPosts[ContactView.ContactID]
            }
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
    
    @IBAction func RemContact(sender: AnyObject) {
    }
}

