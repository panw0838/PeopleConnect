//
//  View+Posts.swift
//  PeopleConnect
//
//  Created by apple on 18/12/30.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

class PostsView: PostsTable, UpdateLocationDelegate, UITableViewDelegate {
    
    @IBOutlet weak var m_tabs: UISegmentedControl!
    @IBOutlet weak var m_posts: UITableView!
    
    func UpdateLocationSuccess() {
        nearPosts.Update()
    }
    
    func UpdateLocationFail() {
    }
    
    func NewGroupAdded() {
        let group = userInfo.groups[0]
        let postData = getGroupPost(group.name)
        postData.Update()
        setTable(m_posts, data: postData, showPhoto: true, showMsg: true)
        m_tabs.setTitle(group.name, forSegmentAtIndex: 3)
    }
    
    @IBAction func switchPosts(sender: AnyObject) {
        let select = (sender as! UISegmentedControl).selectedSegmentIndex
        if select == 0 {
            setTable(m_posts, data: selfPosts, showPhoto: false, showMsg: true)
            if selfPosts.m_needSync {
                selfPosts.Update()
            }
        }
        else if select == 1 {
            setTable(m_posts, data: friendPosts, showPhoto: true, showMsg: true)
            if friendPosts.m_needSync {
                friendPosts.Update()
            }
        }
        else if select == 2 {
            setTable(m_posts, data: nearPosts as PostData, showPhoto: true, showMsg: true)
            if userInfo.x == 0 && userInfo.y == 0 {
                userData.startLocate(self)
            }
        }
        else if select == 3 {
            if userInfo.groups.count == 0 {
                self.performSegueWithIdentifier("ShowSearch", sender: nil)
            }
            else {
                let group = userInfo.groups[0]
                let postData = getGroupPost(group.name)
                postData.Update()
                setTable(m_posts, data: postData, showPhoto: true, showMsg: true)
            }
        }
        m_posts.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if userInfo.groups.count > 0 {
            let name = userInfo.groups[0].name
            m_tabs.setTitle(name, forSegmentAtIndex: 3)
        }
        
        setTable(m_posts, data: friendPosts, showPhoto: true, showMsg: true)
        friendPosts.Update()
        selfPosts.Update()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowSearch" {
            let to = segue.destinationViewController as! SearchGroupView
            to.m_preController = self
        }
    }
}

