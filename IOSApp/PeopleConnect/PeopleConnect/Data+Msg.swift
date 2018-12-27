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
            let messege = json["mess"] as? String
        else {
            return nil
        }
        self.from = UInt64(from.unsignedLongLongValue)
        self.name = name
        self.messege = messege
    }
}

enum MessegeType : Int {
    case String  = 0
    case Request = 1
    case Picture = 2
    case Video   = 3
    case Link    = 4
    case Voice   = 5
}

struct MsgInfo {
    var from:UInt64 = 0
    var time:UInt64 = 0
    var data:String = ""
    var type:MessegeType = .String
    var name = ""
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
        
        let name = json["name"] as? String
        if name != nil {
            self.name = name!
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
            let name = aDecoder.decodeObjectForKey("name") as? String,
            let time = aDecoder.decodeObjectForKey("time") as? NSNumber,
            let data = aDecoder.decodeObjectForKey("cont") as? String,
            let type = aDecoder.decodeObjectForKey("type") as? NSNumber
        else {
            return nil
        }
        m_info.from = UInt64(from.unsignedLongLongValue)
        m_info.name = name
        m_info.time = UInt64(time.unsignedLongLongValue)
        m_info.data = data
        m_info.type = MessegeType(rawValue: type.integerValue)!
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(NSNumber(unsignedLongLong: m_info.from), forKey: "from")
        aCoder.encodeObject(m_info.name, forKey: "name")
        aCoder.encodeObject(NSNumber(unsignedLongLong: m_info.time), forKey: "time")
        aCoder.encodeObject(m_info.data, forKey: "cont")
        aCoder.encodeObject(NSNumber(integer: m_info.type.rawValue), forKey: "type")
    }
}

class Conversation {
    var m_id:UInt64 = 0
    var m_contact:ContactInfo? = nil
    var m_messeges:Array<MsgInfo> = Array<MsgInfo>()
    
    init?(id:UInt64) {
        m_id = id
        let contact = contactsData.getContact(id)
        if contact == nil {
            return nil
        }
        else {
            m_contact = contact
        }
    }
    
    init(contact:ContactInfo) {
        m_id = contact.user
        m_contact = contact
    }
    
    func addMessege(newMessege:MsgInfo) {
        m_messeges.append(newMessege)
    }
    
    func lastMessege()->String? {
        return m_messeges.last?.data
    }
}

protocol MsgDelegate {
    func MsgUpdated()
}

class MsgData {
    var m_conversations:Array<Conversation> = Array<Conversation>()
    var m_delegates = Array<MsgDelegate>()
    var m_rawData = Array<MsgInfo>()
    
    func loadMsgFromCache() {
        let docDir = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let fileName = String(userInfo.userID) + ".msg"
        let path = docDir + "/msgs/" + fileName
        
        let savedData = NSKeyedUnarchiver.unarchiveObjectWithFile(path) as? [MsgInfoCoder]
        if savedData != nil {
            for coder in savedData! {
                let info = coder.m_info
                m_rawData.append(info)
                AddNewMsg(info.from, newMsg: info)
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
        
        for rawData in m_rawData {
            saveData.append(MsgInfoCoder(info: rawData))
        }

        NSKeyedArchiver.archiveRootObject(saveData, toFile: path)
    }
    
    func UpdateDelegates() {
        for delegate in m_delegates {
            delegate.MsgUpdated()
        }
    }
    
    func GetConversation(id:UInt64)->Conversation? {
        for conversation in m_conversations {
            if conversation.m_id == id {
                return conversation
            }
        }
        let conversation = Conversation(id: id)
        if conversation != nil {
            m_conversations.append(conversation!)
        }
        return conversation
    }
    
    func PopConversation(id:UInt64)->Conversation? {
        for (i, conversation) in m_conversations.enumerate() {
            if conversation.m_id == id {
                m_conversations.removeAtIndex(i)
                return conversation
            }
        }
        return nil
    }
    
    func AddNewMsg(id:UInt64, newMsg:MsgInfo) {
        if newMsg.type == .Request {
            let newContact = ContactInfo(id: newMsg.from, f: 0, n: newMsg.name)
            contactsData.m_contacts[newMsg.from] = newContact
        }
        
        var conversation = PopConversation(id)
        if conversation == nil {
            conversation = Conversation(id: id)
        }
        if conversation != nil {
            conversation?.addMessege(newMsg)
            m_conversations.append(conversation!)
        }
    }
}
