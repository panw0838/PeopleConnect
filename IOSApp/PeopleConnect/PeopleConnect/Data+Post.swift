//
//  Post.swift
//  PeopleConnect
//
//  Created by apple on 18/11/29.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation
import UIKit
import AFNetworking

struct PostInfo {
    var user:UInt64 = 0
    var time:UInt64 = 0
    var flag:UInt64 = 0
    var content:String = ""
    var files:Array<String> = Array<String>()
    //var snaps:Array<AnyObject> = Array<AnyObject>()
}

extension PostInfo {
    init?(json: [String: AnyObject]) {
        guard
        let user = json["user"] as? NSNumber,
        let time = json["time"] as? NSNumber,
        let flag = json["flag"] as? NSNumber,
        let content = json["cont"] as? String
        else {
            return nil
        }
        self.user = UInt64(user.unsignedLongLongValue)
        self.time = UInt64(time.unsignedLongLongValue)
        self.flag = UInt64(flag.unsignedLongLongValue)
        self.content = content
        
        let files = json["file"] as? [String]
        self.files = (files == nil ? Array<String>() : files!)
        //let snaps = json["image"] as? [AnyObject]
        //self.snaps = snaps
    }
}

struct CommentInfo {
    var user:UInt64 = 0
    var flag:UInt8 = 0
    var cmt:String = ""
}

extension CommentInfo {
    init?(json:[String:AnyObject]) {
        guard
        let user = json["user"] as? NSNumber,
        let flag = json["flag"] as? NSNumber
        else {
            return nil
        }
        self.user = UInt64(user.unsignedLongLongValue)
        self.flag = UInt8(flag.unsignedCharValue)
        let cmt = json["cmt"] as? String
        self.cmt = (cmt == nil ? "" : cmt!)
    }
}

var postData:PostData = PostData()
let PostItemGap = 8
let PostItemGapF:CGFloat = 8.0

class Post {
    var m_info:PostInfo = PostInfo()
    var m_comments = Array<CommentInfo>()
    var m_imgUrls  = Array<String>()
    var m_imgKeys  = Array<String>()
    var m_preCellGeo = Array<CGRect>()
    
    var m_geoSetted = false
    var m_contentHeight:CGFloat = 0.0
    var m_previewHeight:CGFloat = 0.0
    var m_commentHeight:CGFloat = 0.0
    var m_stackHeight:CGFloat = 0.0
    var m_height:CGFloat = 0.0

    init(info:PostInfo) {
        m_info = info
        
        for file in m_info.files {
            let fileUrl = getFileUrl(info.user, pID: info.time, fileName: file)
            m_imgUrls.append(fileUrl)
            m_imgKeys.append(String(m_info.user) + "_" + String(m_info.time) + "_" + file)
        }
    }
    
    func setupGeometry(width:CGFloat) {
        if m_geoSetted {
            return
        }
        m_geoSetted = true
        
        var m_numStackItems = 0
        m_height = CGFloat(35) + PostItemGapF

        let text:NSString = m_info.content
        if text.length == 0 {
            m_contentHeight = 0.0
        }
        else {
            let maxSize = CGSizeMake(width, CGFloat(MAXFLOAT))
            let size = text.boundingRectWithSize(maxSize, options: .UsesLineFragmentOrigin, attributes: ["NSFontAttributeName":UIFont.systemFontOfSize(13.0)], context: nil)
            let height = Int(size.height + 1.0)
            m_contentHeight = CGFloat(height)
            m_numStackItems++
        }
        
        if m_imgUrls.count == 0 {
            m_previewHeight = 0.0
        }
        else {
            setupPreviewGeo()
            m_previewHeight = 130.0
            m_numStackItems++
        }
        
        m_stackHeight = m_contentHeight + m_previewHeight + (m_numStackItems > 1 ? CGFloat(m_numStackItems-1)*8.0 : 0.0)
        m_height += m_stackHeight
    }
    
    func setupPreviewGeo() {
        let previewCount = m_imgUrls.count
        if previewCount == 1 {
            m_preCellGeo.append(CGRectMake(0, 0, 1, 1))
        }
        else if previewCount == 2 {
            m_preCellGeo.append(CGRectMake(0, 0, 2, 1))
            m_preCellGeo.append(CGRectMake(0, 1, 2, 1))
        }
        else if previewCount == 3 {
            m_preCellGeo.append(CGRectMake(0, 0, 3, 1))
            m_preCellGeo.append(CGRectMake(1, 0, 3, 1))
            m_preCellGeo.append(CGRectMake(2, 0, 3, 1))
        }
        else if previewCount == 4 {
            m_preCellGeo.append(CGRectMake(0, 0, 4, 1))
            m_preCellGeo.append(CGRectMake(1, 0, 4, 1))
            m_preCellGeo.append(CGRectMake(2, 0, 4, 1))
            m_preCellGeo.append(CGRectMake(3, 0, 4, 1))
        }
        else if previewCount == 5 {
            m_preCellGeo.append(CGRectMake(0, 0, 4, 1))
            m_preCellGeo.append(CGRectMake(1, 0, 4, 1))
            m_preCellGeo.append(CGRectMake(2, 0, 4, 1))
            m_preCellGeo.append(CGRectMake(3, 0, 4, 2))
            m_preCellGeo.append(CGRectMake(3, 1, 4, 2))
        }
        else if previewCount == 6 {
            m_preCellGeo.append(CGRectMake(0, 0, 3, 2))
            m_preCellGeo.append(CGRectMake(1, 0, 3, 2))
            m_preCellGeo.append(CGRectMake(2, 0, 3, 2))
            m_preCellGeo.append(CGRectMake(0, 1, 3, 2))
            m_preCellGeo.append(CGRectMake(1, 1, 3, 2))
            m_preCellGeo.append(CGRectMake(2, 1, 3, 2))
        }
        else if previewCount == 7 {
            m_preCellGeo.append(CGRectMake(0, 0, 4, 2))
            m_preCellGeo.append(CGRectMake(1, 0, 4, 2))
            m_preCellGeo.append(CGRectMake(2, 0, 4, 2))
            m_preCellGeo.append(CGRectMake(0, 1, 4, 2))
            m_preCellGeo.append(CGRectMake(1, 1, 4, 2))
            m_preCellGeo.append(CGRectMake(2, 1, 4, 2))
            m_preCellGeo.append(CGRectMake(3, 0, 4, 1))
        }
        else if previewCount == 8 {
            m_preCellGeo.append(CGRectMake(0, 0, 4, 2))
            m_preCellGeo.append(CGRectMake(1, 0, 4, 2))
            m_preCellGeo.append(CGRectMake(2, 0, 4, 2))
            m_preCellGeo.append(CGRectMake(3, 0, 4, 2))
            m_preCellGeo.append(CGRectMake(0, 1, 4, 2))
            m_preCellGeo.append(CGRectMake(1, 1, 4, 2))
            m_preCellGeo.append(CGRectMake(2, 1, 3, 2))
            m_preCellGeo.append(CGRectMake(3, 1, 4, 2))
        }
    }
}

class PostData {
    var m_posts = Array<Post>()
    var m_snaps = Dictionary<String, UIImage>()
    
    func AddPost(info:PostInfo) {
        m_posts.append(Post(info: info))
    }
    
    func numOfPosts()->Int {
        return m_posts.count
    }
    
    func postAtIdx(i:Int)->Post {
        return m_posts[i]
    }
    
    func getPreviews() {
        var files = Array<String>()
        for post in m_posts {
            for key in post.m_imgKeys {
                files.append(key)
            }
        }
        httpGetSnapshots(files)
    }
}