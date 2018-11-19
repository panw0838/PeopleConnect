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

class MessegeSender {
    var m_contact:ContactInfo = ContactInfo(id: 0, f: 0, n: "")
    var m_messeges:Array<MessegeInfo> = Array<MessegeInfo>()
    
    init(from:UInt64) {
        m_contact = contactsData.getContact(from)!
    }
    
    init(contact:ContactInfo) {
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
    var m_senders:Array<MessegeSender> = Array<MessegeSender>()
    
    func GetMessegeSender(from:UInt64)->MessegeSender {
        for sender in m_senders {
            if sender.m_contact.user == from {
                return sender
            }
        }
        let sender = MessegeSender(from: from)
        m_senders.append(sender)
        return sender
    }
    
    func PopMessegeSender(from:UInt64)->MessegeSender? {
        for (i, sender) in m_senders.enumerate() {
            if sender.m_contact.user == from {
                m_senders.removeAtIndex(i)
                return sender
            }
        }
        return nil
    }
    
    func AddNewMessege(newMessege:MessegeInfo) {
        var sender = PopMessegeSender(newMessege.from)
        if sender == nil {
            sender = MessegeSender(from: newMessege.from)
        }
        sender!.addMessege(newMessege)
        m_senders.append(sender!)
    }
    
    func AddNewRequest(newRequest:RequestInfo) {
        let contact = ContactInfo(id: newRequest.from, f: 0, n: newRequest.name)
        let sender = MessegeSender(contact: contact)
        let messege = MessegeInfo(from: newRequest.from, time: "", data: newRequest.messege, type: .Request)
        sender.addMessege(messege)
        m_senders.append(sender)
    }
}

var messegeData:MessegeData = MessegeData()
