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

let PubLvl_Friend:UInt8 = 0
let PubLvl_Group:UInt8 = 1
let PubLvl_Stranger:UInt8 = 2

var friendPosts:PostData = PostData()
var selfPosts:PostData = PostData()
var nearPosts:PostData = PostData()
var previews = Dictionary<String, UIImage>()

struct PostInfo {
    var user:UInt64 = 0
    var id:UInt64 = 0
    var flag:UInt64 = 0
    var content:String = ""
    var files:Array<String> = Array<String>()
    //var snaps:Array<AnyObject> = Array<AnyObject>()
}

extension PostInfo {
    init?(json: [String: AnyObject]) {
        guard
        let user = json["user"] as? NSNumber,
        let id = json["id"] as? NSNumber,
        let flag = json["flag"] as? NSNumber,
        let content = json["cont"] as? String
        else {
            return nil
        }
        self.user = UInt64(user.unsignedLongLongValue)
        self.id = UInt64(id.unsignedLongLongValue)
        self.flag = UInt64(flag.unsignedLongLongValue)
        self.content = content
        
        let files = json["file"] as? [String]
        self.files = (files == nil ? Array<String>() : files!)
        //let snaps = json["image"] as? [AnyObject]
        //self.snaps = snaps
    }
}

struct CommentInfo {
    var from:UInt64 = 0
    var to:UInt64 = 0
    var id:UInt64 = 0
    var cmt:String = ""
    
    func getString()->String {
        var str = ""
        let fromName = contactsData.getContact(from)!.name
        
        if from != to && to != 0 {
            let toName = contactsData.getContact(to)!.name
            str = fromName + "回" + toName + "：" + cmt
        }
        else {
            str = fromName + "：" + cmt
        }
        
        return str
    }
}

extension CommentInfo {
    init?(json:[String:AnyObject]) {
        guard
        let from = json["from"] as? NSNumber,
        let to   = json["to"] as? NSNumber,
        let id   = json["id"] as? NSNumber,
        let cmt  = json["msg"] as? String
        else {
            return nil
        }
        self.from = UInt64(from.unsignedLongLongValue)
        self.to   = UInt64(to.unsignedLongLongValue)
        self.id   = UInt64(id.unsignedLongLongValue)
        self.cmt  = cmt
    }
}

class Post {
    var m_info:PostInfo = PostInfo()
    var m_likes = Array<UInt64>()
    var m_comments = Array<CommentInfo>()
    var m_imgUrls  = Array<String>()
    var m_imgKeys  = Array<String>()
    
    init(info:PostInfo) {
        m_info = info
        
        for file in m_info.files {
            let fileUrl = getFileUrl(info.user, pID: info.id, fileName: file)
            m_imgUrls.append(fileUrl)
            m_imgKeys.append(String(m_info.user) + "_" + String(m_info.id) + "_" + file)
        }
    }
    
    func getHeight(width:CGFloat)->CGFloat {
        let articleHeight = (m_info.content.characters.count == 0 ? 0.0 : (getTextHeight(m_info.content, width: width, font: articleFont) + PostItemGapF))
        let previewHeight = (m_imgUrls.count == 0 ? 0.0 : ((width - PostItemGapF) / 2 + PostItemGapF))
        return articleHeight + previewHeight + 40 + PostItemGapF + 20 + PostItemGapF
    }
}

class PostData {
    var m_posts = Array<Post>()
    
    func AddPost(info:PostInfo) {
        for post in m_posts {
            if post.m_info.id == info.id && post.m_info.user == info.user {
                return
            }
        }
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