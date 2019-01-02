//
//  SinglePostView.swift
//  PeopleConnect
//
//  Created by apple on 19/1/2.
//  Copyright © 2019年 Pan's studio. All rights reserved.
//

import UIKit

class SinglePostView:PostsTable, UITableViewDelegate {
    
    static var SinglePost:Post? = nil
    static var SinglePostSrc:UInt32 = 0
    
    @IBOutlet weak var m_postsTable: UITableView!
    
    override func viewDidLoad() {
        let postData = PostData(src: SinglePostView.SinglePostSrc)
        postData.m_posts.append(SinglePostView.SinglePost!)
        setTable(m_postsTable, data: postData, showPhoto: true, showMsg: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        SinglePostView.SinglePost = nil
    }
}
