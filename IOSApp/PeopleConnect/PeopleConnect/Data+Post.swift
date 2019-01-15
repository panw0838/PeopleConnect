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

enum PostChannel:UInt32 {
    case AllChannel = 0
    case FriendChannel = 1
    case NearChannel = 2
    case GroupChannel = 3
}

var SrcNames:Dictionary<UInt32, String> = [0:"全部", 1:"好友", 2:"附近"]

var selfPosts    = UserPostData(uID:userInfo.userID)
var friendPosts  = FriendPostData()
var nearPosts    = NearPostData()
var groupsPosts   = Dictionary<String, PostData>()
var contactsPosts = Dictionary<UInt64, PostData>()

func getPostData(channel:UInt32, group:String, oID:UInt64)->PostData? {
    if oID == userInfo.userID {
        return selfPosts
    }
    if channel == PostChannel.FriendChannel.rawValue {
        return friendPosts
    }
    if channel == PostChannel.NearChannel.rawValue {
        return nearPosts
    }
    if group.characters.count > 0 {
        return groupsPosts[group]
    }
    return contactsPosts[oID]
}

func getContactPost(cID:UInt64)->PostData {
    var postData:PostData?
    if contactsPosts[cID] == nil {
        postData = UserPostData(uID: cID)
        contactsPosts[cID] = postData
    }
    else {
        postData = contactsPosts[cID]
    }
    return postData!
}

func getGroupPost(group:String)->PostData {
    return groupsPosts[group]!
}

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
    var groups = Array<String>()
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
        
        if let files = json["file"] as? [String] {
            self.files = files
        }
        
        if let groups = json["group"] as? [String] {
            self.groups = groups
        }
        
        if let liked = json["liked"] as? NSNumber {
            self.liked = Bool(liked.boolValue)
        }
        
        if let likes = json["likes"] as? [NSNumber] {
            for like in likes {
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
    var chan:UInt32 = 0
    
    func getUserName(uID:UInt64)->String {
        if uID == 0 {
            return ""
        }
        if uID == userInfo.userID {
            return " 我 "
        }
        return " " + getName(uID) + " "
    }

    func getString(showSrc:Bool)->String {
        let srcName = "[" + SrcNames[chan]! + "]"
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
        let chan = json["chan"] as? NSNumber
        else {
            return nil
        }
        self.from = UInt64(from.unsignedLongLongValue)
        self.to   = UInt64(to.unsignedLongLongValue)
        self.id   = UInt64(id.unsignedLongLongValue)
        self.cmt  = cmt
        self.chan  = UInt32(chan.unsignedIntValue)
    }
}

class Post {
    var m_info:PostInfo = PostInfo()
    var m_father:PostData?
    var m_comments = Array<CommentInfo>()
    var m_actors = Array<UInt64>()
    
    init(info:PostInfo) {
        m_info = info
    }
    
    func sendComment(content:String) {
        httpAddComment(self, to:0, chan:m_father!.getChannel(), cmt:content)
    }
    
    func replyComment(cmt:CommentInfo, content:String) {
        httpAddComment(self, to:cmt.from, chan:cmt.chan, cmt:content)
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
    
    func getPreviews()->Array<UIImage> {
        var images = Array<UIImage>()
        
        for var i=0; i<m_info.files.count; i++ {
            images.append(getPreview(i))
        }
        
        return images
    }
    
    func getLikeString()->String {
        var str:String = "[❤]"
        
        for cID in m_info.likes {
            let name = contactsData.getUser(cID)?.name
            if name != nil {
                str += " " + name! + " "
            }
        }
        
        return str
    }

    func getPermitTags()->Array<Tag> {
        let tags = contactsData.getContactTags()
        var permitTags = Array<Tag>()
        
        for tag in tags {
            if tag.m_bit & m_info.flag != 0 {
                permitTags.append(tag)
            }
        }
        
        return permitTags
    }    
}

protocol PostDataDelegate {
    func PostDataUpdated()->Void
}

class PostData {
    var m_posts = Array<Post>()
    var m_delegate:PostDataDelegate? = nil
    var m_needSync:Bool = false
    var m_lockAt:Int = -1
    
    func setDelegate(delegate:PostDataDelegate?) {
        m_delegate = delegate
    }
    
    func UpdateDelegate() {
        m_delegate?.PostDataUpdated()
    }
    
    func AddPost(info:PostInfo)->Bool {
        var post = getPost(info.id, oID: info.user)
        if post != nil {
            return false
        }
        post = Post(info: info)
        post?.m_father = self
        m_posts.append(post!)
        return true
    }
    
    func getPost(pID:UInt64, oID:UInt64)->Post? {
        for post in m_posts {
            if post.m_info.id == pID && post.m_info.user == oID {
                return post
            }
        }
        return nil
    }
    
    func lockPost(pID:UInt64, oID:UInt64)->Bool {
        for (idx, post) in m_posts.enumerate() {
            if post.m_info.id == pID && post.m_info.user == oID {
                m_lockAt = idx
                return true
            }
        }
        return false
    }
    
    func unLock() {
        m_lockAt = -1
    }
    
    func getLast()->UInt64 {
        return m_posts.count == 0 ? 0 : m_posts.last!.m_info.id
    }
    
    func getChannel()->UInt32 {
        return PostChannel.AllChannel.rawValue
    }
    
    func Update() {
    }
    
    func numOfPosts()->Int {
        if m_lockAt >= 0 {
            return 1
        }
        return m_posts.count
    }
    
    func postAtIdx(i:Int)->Post {
        return m_lockAt == -1 ? m_posts[m_posts.count - i - 1] : m_posts[m_lockAt]
    }
    
    func getContacts() {
        for post in m_posts {
            contactsData.addUser(post.m_info.user, name: "", flag: 0)
            
            for like in post.m_info.likes {
                contactsData.addUser(like, name: "", flag: 0)
            }
            
            for comment in post.m_comments {
                contactsData.addUser(comment.from, name: "", flag: 0)
            }
        }
        contactsData.getUsers(
            { () -> Void in
                self.UpdateDelegate()
            },
            failed: nil)
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

class FriendPostData:PostData {
    
    override init() {
        super.init()
    }
    
    override func getChannel()->UInt32 {
        return PostChannel.FriendChannel.rawValue
    }
    
    override func Update() {
        var pIDs = Array<UInt64>()
        var oIDs = Array<UInt64>()
        var cIDs = Array<UInt64>()
        
        for post in m_posts {
            pIDs.append(post.m_info.id)
            oIDs.append(post.m_info.user)
            cIDs.append((post.m_comments.count == 0 ? 0 : post.m_comments.last!.id))
        }
        
        httpSyncFriendsPost(pIDs, oIDs: oIDs, cIDs: cIDs)
    }
}

class UserPostData:PostData {
    var m_uID:UInt64 = 0
    
    init(uID:UInt64) {
        m_uID = uID
    }

    override func Update() {
        var pIDs = Array<UInt64>()
        var oIDs = Array<UInt64>()
        var cIDs = Array<UInt64>()
        
        for post in m_posts {
            pIDs.append(post.m_info.id)
            oIDs.append(post.m_info.user)
            cIDs.append((post.m_comments.count == 0 ? 0 : post.m_comments.last!.id))
        }
        
        httpSyncContactPost(m_uID, pIDs: pIDs, oIDs: oIDs, cIDs: cIDs)
    }
}

class GroupPostData:PostData {
    var m_group = ""
    var m_chan:UInt32 = 0
    
    init(group:String, chan:UInt32) {
        m_group = group
        m_chan = chan
    }
    
    override func getChannel()->UInt32 {
        return m_chan
    }
    
    override func Update() {
        var pIDs = Array<UInt64>()
        var oIDs = Array<UInt64>()
        var cIDs = Array<UInt64>()
        
        for post in m_posts {
            pIDs.append(post.m_info.id)
            oIDs.append(post.m_info.user)
            cIDs.append((post.m_comments.count == 0 ? 0 : post.m_comments.last!.id))
        }
        
        httpSyncGroupPost(m_group, pIDs: pIDs, oIDs: oIDs, cIDs: cIDs)
    }
}

class NearPostData:PostData {
    // for nearby posts
    var m_gIDs = Array<UInt64>()
    var m_geoPosts = Dictionary<UInt64, PostData>()
    
    func AddPost(gID:UInt64, info:PostInfo) {
        let posts = m_geoPosts[gID]
        posts?.AddPost(info)
    }
    
    override func getChannel()->UInt32 {
        return PostChannel.NearChannel.rawValue
    }
    
    override func Update() {
        httpSyncNearbyPost()
    }
    
    func UpdateSquares() {
        for gid in m_gIDs {
            let geoPosts = m_geoPosts[gid]
            if geoPosts == nil {
                let newSubPostsData = PostData()
                let nilIDs = Array<UInt64>()
                newSubPostsData.setDelegate(m_delegate)
                m_geoPosts[gid] = newSubPostsData
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
                    post.m_father = self
                }
            }
        }

        m_posts.sortInPlace({$0.m_info.id > $1.m_info.id})
    }
    
    override func setDelegate(delegate:PostDataDelegate?) {
        m_delegate = delegate
        for data in m_geoPosts.enumerate() {
            data.element.1.setDelegate(delegate)
        }
    }
}
