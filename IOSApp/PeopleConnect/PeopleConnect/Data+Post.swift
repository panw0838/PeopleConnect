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

let nameFont = UIFont.systemFontOfSize(17.0)
let articleFont = UIFont.systemFontOfSize(15.0)
let commentFont = UIFont.systemFontOfSize(15.0)

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

let PostItemGap = 5
let PostItemGapF:CGFloat = 5.0

func getTextHeight(text:String, width:CGFloat, font:UIFont)->CGFloat {
    let maxSize = CGSizeMake(width, CGFloat(MAXFLOAT))
    let size = text.boundingRectWithSize(maxSize, options: .UsesLineFragmentOrigin, attributes: ["NSFontAttributeName":font], context: nil)
    return CGFloat(Int(size.height + 1.0))
}

class Post {
    var m_info:PostInfo = PostInfo()
    var m_likes = Array<UInt64>()
    var m_comments = Array<CommentInfo>()
    var m_imgUrls  = Array<String>()
    var m_imgKeys  = Array<String>()
    
    var m_geoSetted = false
    var m_width:CGFloat = 0.0
    var m_height:CGFloat = 0.0

    var m_contentHeight:CGFloat = 0.0
    var m_previewHeight:CGFloat = 0.0
    var m_commentHeight:CGFloat = 0.0
    var m_contentY:CGFloat = 0.0
    var m_previewY:CGFloat = 0.0
    var m_commentY:CGFloat = 0.0
    var m_stackHeight:CGFloat = 0.0

    init(info:PostInfo) {
        m_info = info
        
        for file in m_info.files {
            let fileUrl = getFileUrl(info.user, pID: info.id, fileName: file)
            m_imgUrls.append(fileUrl)
            m_imgKeys.append(String(m_info.user) + "_" + String(m_info.id) + "_" + file)
        }
    }
    
    func setupGeometry(width:CGFloat) {
        if m_geoSetted {
            return
        }
        m_geoSetted = true
        m_width = width
        updateGeometry()
    }
    
    func updateGeometry() {
        var numStackItems = 0
        m_height = CGFloat(40)
        m_stackHeight = 0.0
        var buttom = m_height
        
        if m_info.content.characters.count == 0 {
            m_contentHeight = 0.0
        }
        else {
            m_contentY = buttom + PostItemGapF
            m_contentHeight = getTextHeight(m_info.content, width: m_width, font: articleFont)
            m_stackHeight += m_contentHeight
            numStackItems++
            buttom += (m_contentHeight + PostItemGapF)
            m_height += (m_contentHeight + PostItemGapF)
        }
        
        if m_imgUrls.count == 0 {
            m_previewHeight = 0.0
        }
        else {
            m_previewY = buttom + PostItemGapF
            m_previewHeight = (m_width - PostItemGapF) / 2
            m_stackHeight += m_previewHeight
            numStackItems++
            buttom += (m_previewHeight + PostItemGapF)
            m_height += (m_previewHeight + PostItemGapF)
        }

        m_stackHeight += (numStackItems > 1 ? CGFloat(numStackItems-1)*PostItemGapF : 0.0)
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