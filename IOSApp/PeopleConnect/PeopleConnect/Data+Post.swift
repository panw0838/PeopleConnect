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

let UsrPosts:UInt32 = 0
let FriPosts:UInt32 = 1
let StrPosts:UInt32 = 2

var SrcNames:Dictionary<UInt32, String> = [0:"全部", 1:"好友", 2:"附近"]

var selfPosts    = PostData(cid: userInfo.userID)
var friendPosts  = PostData(src: FriPosts)
var nearPosts    = NearPostData(src: StrPosts)
var groupsPosts   = Dictionary<UInt32, PostData>()
var contactsPosts = Dictionary<UInt64, PostData>()

var previews = Dictionary<String, UIImage>()

struct PostInfo {
    var user:UInt64 = 0
    var id:UInt64 = 0
    var flag:UInt64 = 0
    var content:String = ""
    var near  = false
    var liked = false
    var files = Array<String>()
    var likes = Array<UInt64>()
}

extension PostInfo {
    init?(json: [String: AnyObject]) {
        guard
            let user    = json["user"] as? NSNumber,
            let id      = json["id"] as? NSNumber,
            let flag    = json["flag"] as? NSNumber,
            let near    = json["near"] as? NSNumber,
            let content = json["cont"] as? String
        else {
            return nil
        }
        self.user = UInt64(user.unsignedLongLongValue)
        self.id   = UInt64(id.unsignedLongLongValue)
        self.flag = UInt64(flag.unsignedLongLongValue)
        self.near = Bool(near.boolValue)
        self.content = content
        
        let files = json["file"] as? [String]
        self.files = (files == nil ? Array<String>() : files!)
        
        let liked = json["liked"] as? NSNumber
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
            return " 我 "
        }
        return " " + contactsData.getContact(uID)!.name + " "
    }

    func getString(showSrc:Bool)->String {
        let srcName = "[" + SrcNames[src]! + "]"
        let fromName = getUserName(from)
        var str = showSrc ? srcName : ""
        
        if to != 0 {
            let toName = getUserName(to)
            str += fromName + "回" + toName + ":" + cmt
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
        for like in m_info.likes {
            let likeOwner = contactsData.m_contacts[like]
            if likeOwner == nil {
                contactIDs.insert(like)
            }
        }
        if contactIDs.count > 0 {
            httpGetPostsUsers(Array<UInt64>(contactIDs), post: m_father!)
        }
    }
    
    func getLikeString()->String {
        var str:String = "[❤]"
        
        for cID in m_info.likes {
            let name = contactsData.m_contacts[cID]?.name
            
            if name != nil {
                str += " " + name! + " "
            }
        }
        
        return str
    }
    
    func getHeight(width:CGFloat, selfView: Bool, fullView: Bool)->CGFloat {
        let photoHeight = (selfView ? 0 : PostPhotoSize + PostItemGap)
        let articleHeight = (m_info.content.characters.count == 0 ? 0.0 :
            (getTextHeight(m_info.content, width: width, font: articleFont) + PostItemGap))
        let previewHeight = (numImages() == 0 ? 0.0 : ((width - PostPreViewGap*2) / 3 + PostItemGap))
        let toolHeight = PostBtnSize + PostItemGap
        let permitHeight = (selfView ? getPermitHeight(width) + PostItemGap : 0)
        return articleHeight + previewHeight + (fullView ? photoHeight + toolHeight + permitHeight : PostItemGap)
    }
    
    func getPermitTags()->Array<Tag> {
        var tags = Array<Tag>()
        
        for tag in contactsData.m_tags {
            if tag.m_bit & m_info.flag != 0 {
                tags.append(tag)
            }
            for subTag in tag.m_subTags {
                if subTag.m_bit & m_info.flag != 0 {
                    tags.append(subTag)
                }
            }
        }
        
        if contactsData.m_undefine.m_bit & m_info.flag != 0 {
            tags.append(contactsData.m_undefine)
        }
        
        return tags
    }    
}

protocol PostDataDelegate {
    func PostDataUpdated()->Void
}

class PostData {
    var m_sorce:UInt32 = 0
    var m_contact:UInt64 = 0
    var m_posts = Array<Post>()
    var m_delegate:PostDataDelegate? = nil
    
    
    init(src:UInt32) {
        m_sorce = src
    }
    
    init(cid:UInt64) {
        m_sorce = UsrPosts
        m_contact = cid
    }
    
    func AddPost(info:PostInfo) {
        var post = getPost(info.user, pID: info.id)
        if post != nil {
            return
        }
        post = Post(info: info)
        post!.m_father = self
        m_posts.append(post!)
    }
    
    func getPost(oID:UInt64, pID:UInt64)->Post? {
        for post in m_posts {
            if post.m_info.id == pID && post.m_info.user == oID {
                return post
            }
        }
        return nil
    }
    
    func getLast()->UInt64 {
        return m_posts.count == 0 ? 0 : (m_posts.last?.m_info.id)!
    }
    
    func Update() {
        var pIDs = Array<UInt64>()
        var oIDs = Array<UInt64>()
        var cIDs = Array<UInt64>()
        
        for post in m_posts {
            pIDs.append(post.m_info.id)
            oIDs.append(post.m_info.user)
            cIDs.append((post.m_comments.count == 0 ? 0 : post.m_comments.last!.id))
        }
        
        switch m_sorce {
        case UsrPosts:
            httpSyncContactPost(m_contact, pIDs: pIDs, oIDs: oIDs, cIDs: cIDs)
            break
        case FriPosts:
            httpSyncFriendsPost(pIDs, oIDs: oIDs, cIDs: cIDs)
            break
        case StrPosts:
            httpSyncNearbyPost()
            break
        default:
            httpSyncGroupPost(m_sorce, pIDs: pIDs, oIDs: oIDs, cIDs: cIDs)
            break
        }
    }
    
    func setDelegate(delegate:PostDataDelegate) {
        m_delegate = delegate
    }
    
    func UpdateDelegate() {
        m_delegate?.PostDataUpdated()
    }
    
    func numOfPosts()->Int {
        return m_posts.count
    }
    
    func postAtIdx(i:Int)->Post {
        return m_posts[m_posts.count - i - 1]
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

class NearPostData:PostData {
    // for nearby posts
    var m_gIDs = Array<UInt64>()
    var m_geoPosts = Dictionary<UInt64, PostData>()
    
    func AddPost(gID:UInt64, info:PostInfo) {
        let posts = m_geoPosts[gID]
        posts?.AddPost(info)
        posts?.m_posts.last?.m_father = self
    }
    
    func UpdateSquares() {
        for gid in m_gIDs {
            let geoPosts = m_geoPosts[gid]
            if geoPosts == nil {
                m_geoPosts[gid] = PostData(src: StrPosts)
                let nilIDs = Array<UInt64>()
                httpSyncGeoSquarePost(gid, pIDs: nilIDs, oIDs: nilIDs, cIDs: nilIDs)
            }
            else {
                var pIDs = Array<UInt64>()
                var oIDs = Array<UInt64>()
                var cIDs = Array<UInt64>()
                
                for post in (geoPosts?.m_posts)! {
                    pIDs.append(post.m_info.id)
                    oIDs.append(post.m_info.user)
                    cIDs.append((post.m_comments.count == 0 ? 0 : post.m_comments.last!.id))
                }
                
                httpSyncGeoSquarePost(gid, pIDs: pIDs, oIDs: oIDs, cIDs: cIDs)
            }
        }
    }
    
    func reload() {
        m_posts.removeAll()
        
        for gID in m_gIDs {
            let postData = m_geoPosts[gID]
            if postData != nil && postData!.m_posts.count > 0 {
                for post in postData!.m_posts {
                    m_posts.append(post)
                }
            }
        }

        m_posts.sortInPlace({$0.m_info.id > $1.m_info.id})
    }
    
    override func setDelegate(delegate:PostDataDelegate) {
        m_delegate = delegate
        for data in m_geoPosts.enumerate() {
            data.element.1.setDelegate(delegate)
        }
    }
}
