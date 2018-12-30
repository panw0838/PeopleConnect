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

var SrcNames:Dictionary<UInt32, String> = [0:"全部", 1:"好友", 2:"附近"]

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
    var src:UInt32 = 0
    
    func getString(showSrc:Bool)->String {
        let srcName = "[" + SrcNames[src]! + "]"
        let fromName = (from == userInfo.userID ? "我" : contactsData.getContact(from)!.name)
        var str = showSrc ? srcName : ""
        
        if from != to && to != 0 {
            let toName = (to == userInfo.userID ? "我" : contactsData.getContact(to)!.name)
            str += fromName + " 回 " + toName + ":" + cmt
        }
        else {
            str += fromName + ":" + cmt
        }
        
        return str
    }
    
    func getAttrString(showSrc:Bool)->NSMutableAttributedString {
        let fromName = (from == userInfo.userID ? "我" : contactsData.getContact(from)!.name)
        let offset = showSrc ? 4 : 0
        var toStart = offset
        var toLength = 0
        
        if from != to && to != 0 {
            let toName = (to == userInfo.userID ? "我" : contactsData.getContact(to)!.name)
            toStart = fromName.characters.count + 3 + offset
            toLength = toName.characters.count
        }
        
        let str = getString(showSrc)
        let attStr = NSMutableAttributedString(string: str)
        let attDic:Dictionary = [NSForegroundColorAttributeName:UIColor.blackColor()]
        
        attStr.setAttributes(attDic, range: NSMakeRange(0, str.characters.count))
        
        if showSrc {
            attStr.addAttribute(NSForegroundColorAttributeName, value: UIColor.redColor(), range: NSMakeRange(0, 4))
        }
        
        attStr.addAttribute(NSForegroundColorAttributeName, value: linkTextColor, range: NSMakeRange(offset, fromName.characters.count))
        
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
        let cmt  = json["msg"] as? String,
        let src  = json["src"] as? NSNumber
        else {
            return nil
        }
        self.from = UInt64(from.unsignedLongLongValue)
        self.to   = UInt64(to.unsignedLongLongValue)
        self.id   = UInt64(id.unsignedLongLongValue)
        self.cmt  = cmt
        self.src  = UInt32(src.unsignedIntValue)
    }
}

class Post {
    var m_info:PostInfo = PostInfo()
    var m_likes = Array<UInt64>()
    var m_comments = Array<CommentInfo>()
    var m_father:PostData?
    
    init(info:PostInfo) {
        m_info = info
    }
    
    func numImages()->Int {
        return m_info.files.count
    }
    
    func previewExists(idx:Int)->Bool {
        let key = getPreviewKey(m_info, i: idx)
        return (previews[key] == nil)
    }
    
    func getPreview(idx:Int)->UIImage {
        let key = getPreviewKey(m_info, i: idx)
        return (previews[key] == nil ? UIImage(named: "loading")! : previews[key]!)
    }
    
    func getHeight(width:CGFloat, fullView: Bool)->CGFloat {
        let articleHeight = (m_info.content.characters.count == 0 ? 0.0 :
            (getTextHeight(m_info.content, width: width, font: articleFont) + PostItemGapF))
        let previewHeight = (numImages() == 0 ? 0.0 : ((width - PostItemGapF*2) / 3 + PostItemGapF))
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
            for var i=0; i<post.numImages(); i++ {
                let key = getPreviewKey(post.m_info, i: i)
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