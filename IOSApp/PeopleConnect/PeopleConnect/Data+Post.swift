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

let SlfPosts:UInt32 = 0
let UsrPosts:UInt32 = 0
let FriPosts:UInt32 = 1
let StrPosts:UInt32 = 2

var selfPosts    = PostData(src: SlfPosts)
var friendPosts  = PostData(src: FriPosts)
var nearPosts    = PostData(src: StrPosts)
var groupsPosts   = Dictionary<UInt32, PostData>()
var contactsPosts = Dictionary<UInt64, PostData>()

var previews = Dictionary<String, UIImage>()

struct PostInfo {
    var user:UInt64 = 0
    var id:UInt64 = 0
    var flag:UInt64 = 0
    var content:String = ""
    var files:Array<String> = Array<String>()
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
            str = fromName + " 回 " + toName + ":" + cmt
        }
        else {
            str = fromName + ":" + cmt
        }
        
        return str
    }
    
    func getAttrString()->NSMutableAttributedString {
        let fromName = contactsData.getContact(from)!.name
        var toStart = 0
        var toLength = 0
        
        if from != to && to != 0 {
            let toName = contactsData.getContact(to)!.name
            toStart = fromName.characters.count + 3
            toLength = toName.characters.count
        }
        
        let str = getString()
        let attStr = NSMutableAttributedString(string: str)
        let attDic:Dictionary = [NSForegroundColorAttributeName:UIColor.blackColor()]
        
        attStr.setAttributes(attDic, range: NSMakeRange(0, str.characters.count))
        attStr.addAttribute(NSForegroundColorAttributeName, value: linkTextColor, range: NSMakeRange(0, fromName.characters.count))
        
        if toLength != 0 {
            attStr.addAttribute(NSForegroundColorAttributeName, value: linkTextColor, range: NSMakeRange(toStart, toLength))
        }
        
        return attStr
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
    var m_father:PostData?
    
    init(info:PostInfo) {
        m_info = info
        
        for file in m_info.files {
            let fileUrl = getFileUrl(info.user, pID: info.id, fileName: file)
            m_imgUrls.append(fileUrl)
            m_imgKeys.append(String(m_info.user) + "_" + String(m_info.id) + "_" + file)
        }
    }
    
    func getHeight(width:CGFloat, fullView: Bool)->CGFloat {
        let articleHeight = (m_info.content.characters.count == 0 ? 0.0 :
            (getTextHeight(m_info.content, width: width, font: articleFont) + PostItemGapF))
        let previewHeight = (m_imgUrls.count == 0 ? 0.0 : ((width - PostItemGapF*2) / 3 + PostItemGapF))
        return articleHeight + previewHeight + (fullView ? PostPhotoSize + PostItemGapF + PostBtnSize + PostItemGapF : PostItemGapF)
    }
}

protocol PostDataDelegate {
    func PostDataUpdated()->Void
}

class PostData {
    var m_sorce:UInt32 = 0
    var m_posts = Array<Post>()
    var m_delegate:PostDataDelegate? = nil
    
    init(src:UInt32) {
        m_sorce = src
    }
    
    func AddPost(info:PostInfo) {
        for post in m_posts {
            if post.m_info.id == info.id && post.m_info.user == info.user {
                return
            }
        }
        let post = Post(info: info)
        post.m_father = self
        m_posts.append(post)
    }
    
    func Update() {
        m_delegate?.PostDataUpdated()
    }
    
    func numOfPosts()->Int {
        return m_posts.count
    }
    
    func postAtIdx(i:Int)->Post {
        return m_posts[i]
    }
    
    func clear() {
        m_posts.removeAll()
    }
    
    func getContacts() {
        var contactIDs = Set<UInt64>()
        var photoIDs = Set<UInt64>()
        for post in m_posts {
            let postOwner = contactsData.m_contacts[post.m_info.user]
            if postOwner == nil {
                contactIDs.insert(post.m_info.user)
                photoIDs.insert(post.m_info.user)
            }
            else if getContactPhoto(post.m_info.user) == nil {
                photoIDs.insert(post.m_info.user)
            }
            
            for comment in post.m_comments {
                let cmtOwner = contactsData.m_contacts[comment.from]
                if cmtOwner == nil {
                    contactIDs.insert(comment.from)
                }
            }
        }
        if contactIDs.count > 0 {
            httpGetPostsUsers(Array<UInt64>(contactIDs), post: self)
        }
        if photoIDs.count > 0 {
            httpGetPostsPhotos(Array<UInt64>(photoIDs), post:self)
        }
    }
    
    func getPreviews() {
        var files = Array<String>()
        for post in m_posts {
            for key in post.m_imgKeys {
                let preview = getPostPreview(key)
                if preview == nil {
                    files.append(key)
                }
                else {
                    previews[key] = UIImage(data: preview!)
                }
            }
        }
        if files.count > 0 {
            httpGetSnapshots(files, post: self)
        }
    }
}