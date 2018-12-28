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
    case Msg_Voc = 0x03
    case Msg_Lik = 0x04
    
    case Ntf_Req = 0x10
    case Ntf_Add = 0x11
}

let GroupBit:UInt64 = 0x8000000000000000

struct MsgInfo {
    var from:UInt64 = 0
    var time:UInt64 = 0
    var data:String = ""
    var type:MessegeType = .Msg_Str
    var group:UInt32 = 0
    
    func getConversationID()->UInt64 {
        if type == .Ntf_Req {
            return 0
        }
        if group != 0 {
            return UInt64(group) + GroupBit
        }
        return from
    }
}

extension MsgInfo {
    init?(json: [String: AnyObject]) {
        guard
            let from = json["from"] as? NSNumber,
            let time = json["time"] as? NSNumber,
            let data = json["cont"] as? String,
            let type = json["type"] as? NSNumber
        else {
            return nil
        }
        self.from = UInt64(from.unsignedLongLongValue)
        self.time = UInt64(time.unsignedLongLongValue)
        self.data = data
        self.type = MessegeType(rawValue: type.integerValue)!
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
            let time = aDecoder.decodeObjectForKey("time") as? NSNumber,
            let data = aDecoder.decodeObjectForKey("cont") as? String,
            let type = aDecoder.decodeObjectForKey("type") as? NSNumber,
            let group = aDecoder.decodeObjectForKey("group") as? NSNumber
        else {
            return nil
        }
        m_info.from = UInt64(from.unsignedLongLongValue)
        m_info.time = UInt64(time.unsignedLongLongValue)
        m_info.data = data
        m_info.type = MessegeType(rawValue: type.integerValue)!
        m_info.group = UInt32(group.unsignedIntValue)
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(NSNumber(unsignedLongLong: m_info.from), forKey: "from")
        aCoder.encodeObject(NSNumber(unsignedLongLong: m_info.time), forKey: "time")
        aCoder.encodeObject(m_info.data, forKey: "cont")
        aCoder.encodeObject(NSNumber(integer: m_info.type.rawValue), forKey: "type")
        aCoder.encodeObject(NSNumber(unsignedInt: m_info.group), forKey: "group")
    }
}

class Conversation {
    var m_id:UInt64 = 0
    var m_name:String = "未知对话"
    var m_img:UIImage = UIImage(named: "default_profile")!
    var m_messages:Array<MsgInfo> = Array<MsgInfo>()
    
    init(id:UInt64) {
        m_id = id
        
        // new requests
        if id == 0 {
            m_name = "新的朋友"
            m_img = UIImage(named: "messages_requests")!
        }
    }
    
    init(gid:UInt32) {
        m_id = UInt64(gid) + GroupBit
    }
    
    func addMessage(newMessage:MsgInfo) {
        m_messages.append(newMessage)
    }
    
    func remMessage(uid:UInt64, time:UInt64) {
        for (idx, msg) in m_messages.enumerate() {
            if msg.from == uid && time == msg.time {
                m_messages.removeAtIndex(idx)
                break
            }
        }
    }
    
    func lastMessage()->String? {
        if m_id == 0 {
            return m_messages.count > 0 ? String(m_messages.count) + "个新好友申请" : "无新好友申请"
        }
        let lastIdx = m_messages.count - 1
        return getMessage(lastIdx)
    }
    
    func getMessage(idx:Int)->String {
        let msgInfo = m_messages[idx]
        if msgInfo.type == .Ntf_Add {
            return m_name + "已添加你为好友，你们可以对话了"
        }
        return msgInfo.data
    }
}

protocol MsgDelegate {
    func MsgUpdated()
}

class MsgData {
    var m_requests = Array<RequestInfo>()
    var m_conversations = Array<Conversation>()
    var m_delegates = Array<MsgDelegate>()
    var m_requestDelegate:MsgDelegate?
    
    init() {
        // add system conversations
        m_conversations.append(Conversation(id: 0))
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
            for msgInfo in conversation.m_messages {
                saveData.append(MsgInfoCoder(info: msgInfo))
            }
        }

        NSKeyedArchiver.archiveRootObject(saveData, toFile: path)
    }
    
    func UpdateDelegates() {
        for delegate in m_delegates {
            delegate.MsgUpdated()
        }
    }
    
    func UpdateRequestsDelegate() {
        m_requestDelegate?.MsgUpdated()
    }
    
    func getConversation(uID:UInt64)->Conversation {
        for conversation in m_conversations {
            if conversation.m_id == uID {
                return conversation
            }
        }
        return Conversation(id: uID)
    }
    
    func popConversation(id:UInt64)->Conversation {
        for (i, conversation) in m_conversations.enumerate() {
            if conversation.m_id == id {
                m_conversations.removeAtIndex(i)
                return conversation
            }
        }
        return Conversation(id: id)
    }
    
    func AddNewMsg(newMsg:MsgInfo) {
        let convID = newMsg.getConversationID()
        let conversation = popConversation(convID)
        conversation.addMessage(newMsg)
        m_conversations.append(conversation)
        
        // process notifications
        if newMsg.type == .Ntf_Add {
            var contact = contactsData.m_contacts[newMsg.from]
            if contact?.flag == 0 {
                contact?.flag = UndefineBit
                contactsData.m_contacts[newMsg.from] = contact
                contactsData.updateDelegates()
            }
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
