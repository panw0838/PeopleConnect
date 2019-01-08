//
//  Messege.swift
//  PeopleConnect
//
//  Created by apple on 18/11/18.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation

var msgData = MsgData()

struct RequestInfo {
    var from:UInt64 = 0
    var name:String = ""
    var messege:String = ""
}

extension RequestInfo {
    init?(json: [String: AnyObject]) {
        guard
            let from = json["from"] as? NSNumber,
            let name = json["name"] as? String,
            let messege = json["msg"] as? String
        else {
            return nil
        }
        self.from = UInt64(from.unsignedLongLongValue)
        self.name = name
        self.messege = messege
    }
}

enum MessegeType : Int {
    case Msg_Str = 0x00
    case Msg_Pic = 0x01
    case Msg_Vid = 0x02
    
    case Ntf_Req = 0x10
    case Ntf_Add = 0x11
    
    case Ntf_Cmt = 0x20
    case Ntf_Lik = 0x21
    case Ntf_New = 0x22
}

let GroupBit:UInt64 = 0x8000000000000000

struct MsgInfo {
    var type:MessegeType = .Msg_Str
    var time:UInt64 = 0

    var from:UInt64 = 0
    var data:String = ""
    var group:UInt32 = 0
    
    var oID:UInt64 = 0
    var pID:UInt64 = 0
    var src:UInt32 = 0
    
    func getConversationID()->UInt64 {
        if type == .Ntf_Req {
            return 1
        }
        if type == .Ntf_Cmt || type == .Ntf_Lik {
            return 2
        }
        if group != 0 {
            return UInt64(group) + GroupBit
        }
        if from != 0 {
            return from
        }
        return 0
    }
    
    func getMessage()->String {
        if type == .Ntf_Add {
            return "我已添加你为好友，我们可以对话了"
        }
        if type == .Ntf_Cmt {
            return "给你留言"
        }
        if type == .Ntf_Lik {
            return "为你点赞"
        }
        return data
    }
}

extension MsgInfo {
    init?(json: [String: AnyObject]) {
        guard
            let from = json["from"] as? NSNumber,
            let time = json["time"] as? NSNumber,
            let type = json["type"] as? NSNumber
        else {
            return nil
        }
        self.from = UInt64(from.unsignedLongLongValue)
        self.type = MessegeType(rawValue: type.integerValue)!
        self.time = UInt64(time.unsignedLongLongValue)

        if let data = json["cont"] as? String {
            self.data = data
        }
        if let group = json["group"] as? NSNumber {
            self.group = UInt32(group.unsignedIntValue)
        }
        
        if let oID = json["oid"] as? NSNumber {
            self.oID = UInt64(oID.unsignedLongLongValue)
        }
        if let pID = json["pid"] as? NSNumber {
            self.pID = UInt64(pID.unsignedLongLongValue)
        }
        if let src = json["src"] as? NSNumber {
            self.src = UInt32(src.unsignedIntValue)
        }
    }
}

class MsgInfoCoder:NSObject, NSCoding {
    var m_info = MsgInfo()
    
    init(info:MsgInfo) {
        self.m_info = info
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init()
        guard
            let from = aDecoder.decodeObjectForKey("from") as? NSNumber,
            let type = aDecoder.decodeObjectForKey("type") as? NSNumber,
            let time = aDecoder.decodeObjectForKey("time") as? NSNumber
        else {
            return nil
        }
        m_info.from = UInt64(from.unsignedLongLongValue)
        m_info.type = MessegeType(rawValue: type.integerValue)!
        m_info.time = UInt64(time.unsignedLongLongValue)

        if let data = aDecoder.decodeObjectForKey("cont") as? String {
            m_info.data = data
        }
        if let group = aDecoder.decodeObjectForKey("group") as? NSNumber {
            m_info.group = UInt32(group.unsignedIntValue)
        }
        
        if let oID = aDecoder.decodeObjectForKey("oid") as? NSNumber {
            m_info.oID = UInt64(oID.unsignedLongLongValue)
        }
        if let pID = aDecoder.decodeObjectForKey("pid") as? NSNumber {
            m_info.pID = UInt64(pID.unsignedLongLongValue)
        }
        if let src = aDecoder.decodeObjectForKey("src") as? NSNumber {
            m_info.src = UInt32(src.unsignedIntValue)
        }
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(NSNumber(unsignedLongLong: m_info.from), forKey: "from")
        aCoder.encodeObject(NSNumber(integer: m_info.type.rawValue), forKey: "type")
        aCoder.encodeObject(NSNumber(unsignedLongLong: m_info.time), forKey: "time")

        aCoder.encodeObject(m_info.data, forKey: "cont")
        aCoder.encodeObject(NSNumber(unsignedInt: m_info.group), forKey: "group")
        
        aCoder.encodeObject(NSNumber(unsignedLongLong: m_info.oID), forKey: "oid")
        aCoder.encodeObject(NSNumber(unsignedLongLong: m_info.pID), forKey: "pid")
        aCoder.encodeObject(NSNumber(unsignedInt: m_info.src), forKey: "src")
    }
}

enum ConvType: UInt64 {
    case ConvRequest = 1
    case ConvPostNTF = 2
}

protocol ConvDelegate {
    func ConvUpdated()
    func MsgSend(idx:Int)
    func MsgSentSuccess(idx:Int)
    func MsgSentFail(idx:Int)
}

class Conversation {
    var m_id:UInt64 = 0
    var m_name:String = "未知对话"
    var m_img:UIImage = UIImage(named: "default_profile")!
    var m_messages:Array<MsgInfo> = Array<MsgInfo>()
    var m_delegate:ConvDelegate?
    var m_newMsg = false
    
    init() {
    }
    
    init(id:UInt64) {
        m_id = id
        
        // new requests
        if id == ConvType.ConvRequest.rawValue {
            m_name = "好友申请"
            m_img = UIImage(named: "messages_requests")!
        }
        else if id == ConvType.ConvPostNTF.rawValue {
            m_name = "动态通知"
            m_img = UIImage(named: "messages_notify")!
        }
        else if (m_id & GroupBit) != 0 {
        }
        else {
            let contact = contactsData.m_contacts[m_id]
            if contact != nil {
                m_name = getName(m_id)
                m_img = getPhoto(m_id)
            }
        }
    }
    
    init(gid:UInt32) {
        m_id = UInt64(gid) + GroupBit
    }
    
    func UpdateDelegate() {
        m_delegate?.ConvUpdated()
    }
    
    func addMessage(newMessage:MsgInfo) {
        m_messages.append(newMessage)
        m_newMsg = true
        UpdateDelegate()
        msgData.UpdateDelegate()
    }
    
    func sendMessage(from:UInt64, message:String, type:MessegeType) {
        let idx = m_messages.count
        var selfMessege = MsgInfo()
        selfMessege.from = from
        selfMessege.time = 0
        selfMessege.data = message
        selfMessege.type = type
        addMessage(selfMessege)
        m_delegate?.MsgSend(idx)
        httpSendMessege(m_id, messege: message,
            passed: {(timeID:UInt64)->Void in
                self.m_messages[idx].time = timeID
                self.m_delegate?.MsgSentSuccess(idx)
            },
            failed: {()->Void in
                self.m_delegate?.MsgSentFail(idx)
            }
        )
    }
    
    func lastMessage()->String? {
        if m_id == ConvType.ConvRequest.rawValue {
            return String(m_messages.count) + "个新申请"
        }
        else if m_id == ConvType.ConvPostNTF.rawValue {
            return String(m_messages.count) + "个动态通知"
        }
        return m_messages.last?.getMessage()
    }
}

class Requests:Conversation {
    
}

class PostNotifies:Conversation {
    
    var m_posts = Array<Post>()
    
    override init() {
        super.init()
        m_id = ConvType.ConvPostNTF.rawValue
        m_name = "动态通知"
        m_img = UIImage(named: "messages_notify")!
    }
    
    override func addMessage(newMessage:MsgInfo) {
        super.addMessage(newMessage)
        
        if let postData = getPostData(newMessage.src, oID: newMessage.oID) {
            postData.m_needSync = true
            if let post = postData.getPost(newMessage.pID, oID: newMessage.oID) {
                for (idx, oldPost) in m_posts.enumerate() {
                    if oldPost.m_father?.m_sorce == post.m_father?.m_sorce &&
                        oldPost.m_info.id == post.m_info.id &&
                        oldPost.m_info.user == post.m_info.user {
                        m_posts.removeAtIndex(idx)
                    }
                }
                m_posts.append(post)
                post.m_actors.append(newMessage.from)
            }
        }
    }
    
    func getMessage(idx:Int)->String {
        let post = m_posts[idx]
        let src = post.m_father?.m_sorce
        return String(post.m_actors.count) + "个人" + (src == UsrPosts ?  "评论了你的动态" : "回复了你的评论")
    }

    override func lastMessage() -> String? {
        return String(m_messages.count) + "个动态通知"
    }
}

protocol MsgDelegate {
    func MsgUpdated()
}

protocol ReqDelegate {
    func ReqUpdated()
}

class MsgData {
    var m_requests = Array<RequestInfo>()
    var m_conversations = Array<Conversation>()
    var m_delegate:MsgDelegate?
    var m_requestDelegate:ReqDelegate?
    
    init() {
        // add system conversations
        m_conversations.append(Conversation(id: 1))
        m_conversations.append(PostNotifies())
        
        loadMsgFromCache()
    }
    
    func loadMsgFromCache() {
        let docDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let fileName = String(userInfo.userID) + ".msg"
        let path = docDir + "/msgs/" + fileName
        
        let savedData = NSKeyedUnarchiver.unarchiveObjectWithFile(path) as? [MsgInfoCoder]
        if savedData != nil {
            for coder in savedData! {
                let info = coder.m_info
                AddNewMsg(info)
            }
        }
    }
    
    func saveMsgToCache() {
        let fileMgr = NSFileManager.defaultManager()
        let docDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let fileName = String(userInfo.userID) + ".msg"
        let folder = docDir + "/msgs"
        let path = docDir + "/msgs/" + fileName

        if !fileMgr.fileExistsAtPath(folder) {
            do {
                try fileMgr.createDirectoryAtPath(folder, withIntermediateDirectories: true, attributes: nil)
            } catch {}
        }
        
        var saveData = Array<MsgInfoCoder>()
        
        for conversation in m_conversations {
            // skip notifications
            if conversation.m_id < 10 {
                continue
            }
            for msgInfo in conversation.m_messages {
                saveData.append(MsgInfoCoder(info: msgInfo))
            }
        }

        NSKeyedArchiver.archiveRootObject(saveData, toFile: path)
    }
    
    func Update() {
        httpSyncMessege(nil, failed: nil)
    }
    
    func UpdateRequests() {
        httpSyncRequests()
    }
    
    func UpdateDelegate() {
        m_delegate?.MsgUpdated()
    }
    
    func UpdateRequestsDelegate() {
        m_requestDelegate?.ReqUpdated()
    }

    func popConversation(id:UInt64)->Conversation {
        var conv:Conversation? = nil
        
        for (i, conversation) in m_conversations.enumerate() {
            if conversation.m_id == id {
                m_conversations.removeAtIndex(i)
                conv = conversation
            }
        }
        
        if conv == nil {
            conv = Conversation(id: id)
        }
        
        m_conversations.append(conv!)
        
        return conv!
    }
    
    func AddNewMsg(newMsg:MsgInfo) {
        let convID = newMsg.getConversationID()
        
        if convID != 0 {
            let conversation = popConversation(convID)
            conversation.addMessage(newMsg)
            UpdateDelegate()    // data changed
        }
    }
    
    func remRequest(uid:UInt64) {
        for (idx, req) in m_requests.enumerate() {
            if req.from == uid {
                m_requests.removeAtIndex(idx)
                break
            }
        }
    }
}
