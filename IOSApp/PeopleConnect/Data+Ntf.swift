//
//  Data+Ntf.swift
//  PeopleConnect
//
//  Created by apple on 19/1/18.
//  Copyright © 2019年 Pan's studio. All rights reserved.
//

import Foundation

class RequestNotifies:Conversation {
    
    var m_requests = Array<RequestInfo>()
    
    func addRequest(request:RequestInfo) {
        for msg in m_messages {
            if request.from == msg.m_info.from {
                m_requests.insert(request, atIndex: 0)
                return
            }
        }
        m_requests.append(request)
    }
    
    func remRequest(uid:UInt64) {
        for (idx, req) in m_requests.enumerate() {
            if req.from == uid {
                m_requests.removeAtIndex(idx)
                break
            }
        }
    }
    
    override init() {
        super.init()
        m_id = ConvType.ConvRequest.rawValue
    }
    
    override func getConvName()->String {
        return "好友通知"
    }
    
    override func getConvPhoto()->UIImage {
        return UIImage(named: "messages_requests")!
    }
    
    func UpdateRequests() {
        httpSyncRequests()
    }
    
    override func getUserAt(index:Int)->UInt64 {
        return m_requests[index].from
    }
    
    override func numMessages() -> Int {
        return m_requests.count
    }
    
    override func getMessage(idx:Int)->String {
        return m_requests[idx].messege
    }
    
    override func lastMessage() -> String? {
        return String(m_messages.count) + "个新申请"
    }
}

class LikeNotifies:Conversation {
    
    var m_likers = Array<UInt64>()
    
    override init() {
        super.init()
        m_id = ConvType.ConvLikeUsr.rawValue
    }
    
    override func getConvName()->String {
        return "点赞通知"
    }
    
    override func getConvPhoto()->UIImage {
        return UIImage(named: "group_like")!
    }
    
    func addLiker(liker:UInt64) {
        for msg in m_messages {
            if liker == msg.m_info.from {
                m_likers.insert(liker, atIndex: 0)
                return
            }
        }
        m_likers.append(liker)
    }
    
    override func getUserAt(index:Int)->UInt64 {
        return m_likers[index]
    }
    
    override func numMessages() -> Int {
        return m_likers.count
    }
    
    override func getMessage(idx:Int)->String {
        return "为你点赞"
    }
    
    override func lastMessage() -> String? {
        return String(m_messages.count) + "个新点赞"
    }
}

class PostNotifies:Conversation {
    
    var m_posts = Array<Post>()
    
    override init() {
        super.init()
        m_id = ConvType.ConvPostNTF.rawValue
    }
    
    override func getConvName()->String {
        return "动态通知"
    }
    
    override func getConvPhoto()->UIImage {
        return UIImage(named: "messages_notify")!
    }
    
    override func addMessage(newMessage:MsgInfo, newMsg:Bool) {
        super.addMessage(newMessage, newMsg: newMsg)
        
        if let postData = getPostData(newMessage.chan, group: newMessage.pGroup, oID: newMessage.oID) {
            postData.m_needSync = true
            if let post = postData.getPost(newMessage.pID, oID: newMessage.oID) {
                for (idx, oldPost) in m_posts.enumerate() {
                    if oldPost.m_father?.getChannel() == post.m_father?.getChannel() &&
                        oldPost.m_info.id == post.m_info.id &&
                        oldPost.m_info.user == post.m_info.user {
                            m_posts.removeAtIndex(idx)
                    }
                }
                m_posts.append(post)
                for actor in post.m_actors {
                    if actor == newMessage.from {
                        return
                    }
                }
                post.m_actors.append(newMessage.from)
            }
        }
    }
    
    override func numMessages() -> Int {
        return m_posts.count
    }
    
    override func getMessage(idx:Int)->String {
        let post = m_posts[idx]
        let selfPost = (post.m_father?.getChannel() == PostChannel.AllChannel.rawValue)
        return String(post.m_actors.count) + "个人" + (selfPost ? "评论了你的动态" : "回复了你的评论")
    }
    
    override func lastMessage() -> String? {
        return String(m_messages.count) + "个动态通知"
    }
}
