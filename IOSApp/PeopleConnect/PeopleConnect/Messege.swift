//
//  Messege.swift
//  PeopleConnect
//
//  Created by apple on 18/11/18.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation

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

enum MessegeType {
    case Request
    case String
    case Link
    case Sound
    case Video
}

struct MessegeInfo {
    var from:UInt64 = 0
    var time:String = ""
    var data:String = ""
    var type:MessegeType = .String
}

extension MessegeInfo {
    init?(json: [String: AnyObject]) {
        guard
            let from = json["from"] as? NSNumber,
            let time = json["time"] as? String,
            let data = json["cont"] as? String
            else {
                return nil
        }
        self.from = UInt64(from.unsignedLongLongValue)
        self.time = time
        self.data = data
    }
}

class Conversation {
    var m_id:UInt64 = 0
    var m_contact:ContactInfo = ContactInfo(id: 0, f: 0, n: "")
    var m_messeges:Array<MessegeInfo> = Array<MessegeInfo>()
    
    init(id:UInt64) {
        m_id = id
        m_contact = contactsData.getContact(id)!
    }
    
    init(contact:ContactInfo) {
        m_id = contact.user
        m_contact = contact
    }
    
    func addMessege(newMessege:MessegeInfo) {
        m_messeges.append(newMessege)
    }
    
    func lastMessege()->String? {
        return m_messeges.last?.data
    }
}

class MessegeData {
    var m_conversations:Array<Conversation> = Array<Conversation>()
    
    func GetConversation(id:UInt64)->Conversation {
        for conversation in m_conversations {
            if conversation.m_id == id {
                return conversation
            }
        }
        let conversation = Conversation(id: id)
        m_conversations.append(conversation)
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
    
    func AddNewMessege(id:UInt64, newMessege:MessegeInfo) {
        var conversation = PopConversation(id)
        if conversation == nil {
            conversation = Conversation(id: id)
        }
        conversation!.addMessege(newMessege)
        m_conversations.append(conversation!)
    }
    
    func AddNewRequest(newRequest:RequestInfo) {
        let conversation = GetConversation(newRequest.from)
        let messege = MessegeInfo(from: newRequest.from, time: "", data: newRequest.messege, type: .Request)
        conversation.addMessege(messege)
    }
}

var messegeData:MessegeData = MessegeData()
