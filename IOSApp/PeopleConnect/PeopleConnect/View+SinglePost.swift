//
//  SinglePostView.swift
//  PeopleConnect
//
//  Created by apple on 19/1/2.
//  Copyright © 2019年 Pan's studio. All rights reserved.
//

import UIKit

class SinglePostView:PostsTable, UITableViewDelegate {
    
    static var postData:PostData?
    
    @IBOutlet weak var m_postsTable: UITableView!
    
    override func viewDidLoad() {
        setTable(m_postsTable, data: SinglePostView.postData!, showPhoto: true, showMsg: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        SinglePostView.postData!.unLock()
    }
}
