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
    
    @IBOutlet weak var m_profile: UIImageView!
    @IBOutlet weak var m_name: UILabel!
    @IBOutlet weak var m_article: UILabel!
    @IBOutlet weak var m_previews: UICollectionView!
    @IBOutlet weak var m_comments: UITableView!
    @IBOutlet weak var m_stack: UIStackView!
    
    var m_idx:Int = 0
    var m_post:Post? = nil
    var m_cellSize:CGFloat = 0.0
    let preGap:CGFloat = 5.0

    func reload() {
        m_post = postData.postAtIdx(m_idx)

        let contact = contactsData.getContact((m_post?.m_info.user)!)
        m_name.text = contact?.name
        m_article.text = m_post?.m_info.content
        
        // sub view rects
        m_article.frame.size = CGSizeMake(m_article.frame.width, (m_post?.m_contentHeight)!)
        m_previews.frame.size = CGSizeMake(m_previews.frame.width, (m_post?.m_previewHeight)!)
        m_stack.frame.size = CGSizeMake(m_stack.frame.width, ((m_post?.m_stackHeight)!))
        
        m_article.backgroundColor = UIColor.yellowColor()
        
        let text:NSString = m_article.text!
        if text.length > 0 {
            m_article.hidden = false
        }
        else {
            m_article.hidden = true
        }
        
        if m_post?.m_imgUrls.count > 0 {
            m_previews.hidden = false
            m_previews.dataSource = self
            m_previews.delegate = self
            m_previews.reloadData()
        }
        else {
            m_previews.hidden = true
        }
        
        m_comments.hidden = true
    }
        
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (m_post?.m_info.files.count)!
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PreviewCell", forIndexPath: indexPath) as! PreviewCell
        let imgKey = m_post?.m_imgKeys[indexPath.row]
        if postData.m_snaps[imgKey!] == nil {
            cell.m_preview.image = UIImage(named: "loading")
        }
        else {
            cell.m_preview.image = postData.m_snaps[imgKey!]
        }
        
        let frame = m_previews.frame
        if indexPath.row < 9 {
            let geo = m_post!.m_preCellGeo[indexPath.row]
            let width  = (frame.width  - preGap * (geo.width-1)) / geo.width
            let height = (frame.height - preGap * (geo.height-1)) / geo.height
            let x = (width  + preGap) * geo.origin.x
            let y = (height + preGap) * geo.origin.y
            cell.frame = CGRectMake(x, y, width, height)
        }
        else {
            cell.frame = frame
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        /*
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
        return
    }
}

class PostsView: UIViewController, PostRequestCallback, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var m_tabs: UISegmentedControl!
    @IBOutlet weak var m_posts: UITableView!
    
    @IBAction func switchPosts(sender: AnyObject) {
    }
    
    override func viewDidLoad() {
        httpSyncPost()
        postCallbacks.append(self)
        m_posts.estimatedRowHeight = 80
        m_posts.rowHeight = UITableViewAutomaticDimension
    }
    
    func PostUpdateUI() {
        m_posts.reloadData()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postData.numOfPosts()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PostCell") as! PostCell
        let post = postData.postAtIdx(indexPath.row)
        let contentWidth = m_posts.contentSize.width - PostItemGapF * 2
        cell.m_idx = indexPath.row
        post.setupGeometry(contentWidth)
        cell.reload()
        return cell
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let post = postData.postAtIdx(indexPath.row)
        let contentWidth = m_posts.contentSize.width - PostItemGapF * 2
        post.setupGeometry(contentWidth)
        return post.m_height
    }
}
