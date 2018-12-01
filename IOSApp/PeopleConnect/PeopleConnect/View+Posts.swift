//
//  PostsView.swift
//  PeopleConnect
//
//  Created by apple on 18/11/11.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

class PreviewCell: UICollectionViewCell {
    
    @IBOutlet weak var m_preview: UIImageView!
    
}

class PostCell: UITableViewCell, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var m_previews: UICollectionView!
    
    var m_idx:Int = 0
    var m_post:Post? = nil
    
    func reload() {
        m_post = postData.postAtIdx(m_idx)
        m_previews.dataSource = self
        m_previews.delegate = self
        m_previews.reloadData()
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (m_post?.m_info.files.count)!
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PreviewCell", forIndexPath: indexPath) as! PreviewCell
        /*
        cell.m_preview.image = UIImage(named: "loading")
        http.getFile((m_post?.m_imgUrls[indexPath.row])!,
            success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
                let data = response as! NSData
                cell.m_preview.image = UIImage(data: data)
            },
            fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
                print("请求失败")
            }
        )
*/
        let imgKey = m_post?.m_imgKeys[indexPath.row]
        if postData.m_snaps[imgKey!] == nil {
            cell.m_preview.image = UIImage(named: "loading")
        }
        else {
            cell.m_preview.image = postData.m_snaps[imgKey!]
        }
        return cell
    }
}

class PostsView: UITableViewController, PostRequestCallback, UIImagePickerControllerDelegate {
    
    override func viewDidLoad() {
        httpSyncPost()
        postCallbacks.append(self)
    }
    
    func PostUpdateUI() {
        self.tableView.reloadData()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postData.numOfPosts()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PostCell") as! PostCell
        cell.m_idx = indexPath.row
        cell.reload()
        return cell
    }
}
