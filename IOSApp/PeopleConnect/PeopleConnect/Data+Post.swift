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
    var liked = false
    var files = Array<String>()
    var likes = Array<UInt64>()
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
        
        let liked = json["like"] as? NSNumber
        self.liked = (liked == nil ? false : Bool(liked!.boolValue))
        
        let likes = json["likes"] as? [NSNumber]
        if likes != nil {
            for like in likes! {
                let uID = UInt64(like.unsignedLongLongValue)
                self.likes.append(uID)
            }
        }
    }
}

struct CommentInfo {
    var from:UInt64 = 0
    var to:UInt64 = 0
    var id:UInt64 = 0
    var cmt:String = ""
    var src:UInt32 = 0
    
    func getUserName(uID:UInt64)->String {
        if uID == 0 {
            return ""
        }
        if uID == userInfo.userID {
            return "我"
        }
        return contactsData.getContact(uID)!.name
    }

    func getString(showSrc:Bool)->String {
        let srcName = "[" + SrcNames[src]! + "]"
        let fromName = getUserName(from)
        var str = showSrc ? srcName : ""
        
        if to != 0 {
            let toName = getUserName(to)
            str += fromName + " 回 " + toName + ":" + cmt
        }
        else {
            str += fromName + ":" + cmt
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
    
    func getLikeContacts() {
        var contactIDs = Set<UInt64>()
        var photoIDs = Set<UInt64>()
        for like in m_info.likes {
            let likeOwner = contactsData.m_contacts[like]
            if likeOwner == nil {
                contactIDs.insert(like)
            }
            else if getContactPhoto(like) == nil {
                photoIDs.insert(like)
            }
        }
        if contactIDs.count > 0 {
            //httpGetPostsUsers(Array<UInt64>(contactIDs), post: self)
        }
        if photoIDs.count > 0 {
            //httpGetPostsPhotos(Array<UInt64>(photoIDs), post:self)
        }
    }
    
    func getLikeString()->String {
        var str:String = "[❤]"
        
        for cID in m_info.likes {
            let name = contactsData.m_contacts[cID]?.name
            
            if name != nil {
                str += " " + name!
            }
        }
        
        return str
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
        return m_posts[m_posts.count - i - 1]
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