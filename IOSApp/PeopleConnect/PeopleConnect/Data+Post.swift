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

var postData:PostData = PostData()
let PostItemGap = 8
let PostItemGapF:CGFloat = 8.0

class Post {
    var m_info:PostInfo = PostInfo()
    var m_imgUrls:Array<String> = Array<String>()
    var m_imgKeys:Array<String> = Array<String>()
    
    var m_contentY:CGFloat = 0.0
    var m_contentHeight:CGFloat = 0.0
    var m_previewY:CGFloat = 0.0
    var m_previewHeight:CGFloat = 0.0
    var m_commentY:CGFloat = 0.0
    var m_commentHeight:CGFloat = 0.0
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
        var bottom:CGFloat = CGFloat(PostItemGap + 35)
        m_height = CGFloat(PostItemGap + 35 + PostItemGap)

        let text:NSString = m_info.content
        m_contentY = bottom + PostItemGapF
        if text.length == 0 {
            m_contentHeight = 0.0
        }
        else {
            let maxSize = CGSizeMake(width, CGFloat(MAXFLOAT))
            let size = text.boundingRectWithSize(maxSize, options: .UsesLineFragmentOrigin, attributes: ["NSFontAttributeName":UIFont.systemFontOfSize(13.0)], context: nil)
            let height = Int(size.height + 1.0)
            m_contentHeight = CGFloat(height)
            bottom += (PostItemGapF + m_contentHeight)
            m_height += (m_contentHeight + PostItemGapF)
        }
        
        m_previewY = bottom + PostItemGapF
        if m_imgUrls.count == 0 {
            m_previewHeight = 0.0
        }
        else {
            m_previewHeight = 130.0
            bottom += (PostItemGapF + m_previewHeight)
            m_height += (m_previewHeight + PostItemGapF)
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