//
//  Contact.swift
//  PeopleConnect
//
//  Created by apple on 18/11/11.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation

struct ContactInfo {
    var user: UInt64
    var flag: UInt64
    var name: String
    var ip: String
    
    init(id:UInt64, f:UInt64, n:String) {
        user = id
        flag = f
        name = n
        ip = ""
    }
    
    func isBlacklist()->Bool {
        return (flag & BlacklistBit) == BlacklistBit
    }
    
    func isUndefine()->Bool {
        return (flag & RelateTagMask) == UndefineBit
    }
}

extension ContactInfo {
    init?(json: [String: AnyObject]) {
        guard
            let user = json["user"] as? NSNumber,
            let flag = json["flag"] as? NSNumber,
            let name = json["name"] as? String
        else {
            return nil
        }
        self.user = UInt64(user.unsignedLongLongValue)
        self.flag = UInt64(flag.unsignedLongLongValue)
        self.name = name
        self.ip = ""
    }
}

let BitOne: UInt64 = 0x1
let BlacklistBit: UInt64 = 0x1
let UndefineBit: UInt64 = 0x2
let SystemTagStart: UInt64 = 0x1
let SystemTagEnd: UInt64 = 0x20
let DefineTagStart: UInt64 = 0x100000000
let DefineTagEnd: UInt64 = 0x8000000000000000
let DefineTagMask: UInt64 = 0xFFFFFFFF00000000
let RelateTagMask: UInt64 = (DefineTagMask | 0x3E)

struct TagInfo {
    var tagID: UInt8
    var fatherID: UInt8
    var tagName: String
    
    init(id:UInt8, father:UInt8, name:String) {
        tagID = id
        fatherID = father
        tagName = name
    }
}

extension TagInfo {
    init?(json: [String: AnyObject]) {
        guard
            let tagID = json["id"] as? NSNumber,
            let fatherID = json["father"] as? NSNumber,
            let tagName = json["name"] as? String
        else {
            return nil
        }
        self.tagID = UInt8(tagID.unsignedCharValue)
        self.fatherID = UInt8(fatherID.unsignedCharValue)
        self.tagName = tagName
    }
}

class Tag {
    var m_tagID: UInt8 = 0
    var m_fatherID: UInt8 = 0
    var m_bit: UInt64 = 0
    var m_fatherBit:UInt64 = 0
    var m_subBits: UInt64 = 0
    var m_tagName: String = ""
    var m_members: Array<UInt64> = Array<UInt64>()
    var m_subTags: Array<Tag> = Array<Tag>()
    
    init(id: UInt8, father: UInt8, name: String) {
        m_tagID = id
        m_fatherID = father
        m_tagName = name

        if id != 0xff {
            m_bit = (BitOne << UInt64(id))
            m_fatherBit = (father == 0 ? 0 : (BitOne << UInt64(father)))
        }
    }
    
    func canBeDelete()->Bool {
        return (m_tagID != 0xff)
            && ((m_bit & DefineTagMask) != 0)
            && (m_members.count == 0)
            && (m_subTags.count == 0)
    }
    
    func canBeEdit()->Bool {
        return (m_tagID != 0xff) && (m_bit & UndefineBit) == 0
    }
    
    func addMember(contact: ContactInfo) {
        if (m_subBits & contact.flag) != 0 {
            for subTag in m_subTags {
                subTag.addMember(contact)
            }
        }
        else if (m_bit & contact.flag) != 0 {
            m_members.append(contact.user)
        }
    }
    
    func remMember(contactID: UInt64) {
        for subTag in m_subTags {
            subTag.remMember(contactID)
        }

        for (index, member) in m_members.enumerate() {
            if contactID == member {
                m_members.removeAtIndex(index)
                return
            }
        }
    }
    
    func addSubTag(tag: Tag) {
        m_subTags.append(tag)
        if tag.m_tagID != 0xff {
            m_subBits |= (BitOne << UInt64(tag.m_tagID))
        }
    }
    
    func remSubTag(tagID: UInt8) {
        var idx = 0
        for subTag in m_subTags {
            if subTag.m_tagID == tagID {
                m_subTags.removeAtIndex(idx)
                m_subBits &= ~(BitOne << UInt64(tagID))
                break
            }
            idx++
        }
    }
    
    func getNumSubTags()->Int {
        return m_subTags.count
    }
    
    func getSubTagName(subIdx: Int)->String {
        return m_subTags[subIdx].m_tagName
    }
    
    func getMembers()->Array<UInt64> {
        return m_members
    }
}

var contactsData:ContactsData = ContactsData()

class ContactsData {
    var m_blacklist: Tag = Tag(id: 0, father: 0, name: "黑名单")
    var m_undefine:Tag? = nil
    var m_possible: Tag? = nil
    var m_stranger:Tag? = nil
    var m_tags: Array<Tag> = Array<Tag>()
    var m_contacts:Dictionary<UInt64, ContactInfo> = Dictionary<UInt64, ContactInfo>()

    init() {
        m_tags.removeAll()
        m_contacts.removeAll()
        initSystemTags()
    }
    
    func initSystemTags() {
        m_blacklist.m_members.removeAll()
        // system tags
        m_tags.append(Tag(id: 2, father: 0, name: "家人"))
        m_tags.append(Tag(id: 3, father: 0, name: "同学"))
        m_tags.append(Tag(id: 4, father: 0, name: "同事"))
        m_tags.append(Tag(id: 5, father: 0, name: "朋友"))
        m_tags.append(Tag(id: 1, father: 0, name: "未分类"))
        m_undefine = m_tags.last!
        m_tags.append(Tag(id: 0xff, father: 0, name: ""))
        m_tags.last!.addSubTag(Tag(id: 0xff, father: 0, name: "可能认识的人"))
        m_possible = m_tags.last!.m_subTags.last
        m_tags.last!.addSubTag(Tag(id: 0xff, father: 0, name: "附近的陌生人"))
        m_stranger = m_tags.last!.m_subTags.last
    }
    
    func numMainTags()->Int {
        return m_tags.count
    }
    
    func getMainTag(idx:Int)->Tag {
        return m_tags[idx]
    }
    
    func numSubTags(idx:Int)->Int {
        let tag = getMainTag(idx)
        return tag.m_subTags.count + (tag.m_tagID == 0xff ? 0 : 1)
    }

    func getSubTag(idx:Int, subIdx:Int)->Tag {
        let tag = getMainTag(idx)
        if subIdx == tag.m_subTags.count {
            return tag
        }
        else {
            return tag.m_subTags[subIdx]
        }
    }
    
    func addSubTag(newTag: Tag) {
        let fatherTag: Tag = m_tags[Int(newTag.m_fatherID) - 2]
        fatherTag.addSubTag(newTag)
    }
    
    func getTag(tagID: UInt8)->Tag? {
        if tagID == 0 {
            return m_blacklist
        }
        else if tagID == 1 {
            return m_undefine
        }
        else {
            for tag in m_tags {
                if tag.m_tagID == tagID {
                    return tag
                }
                for sub in tag.m_subTags {
                    if sub.m_tagID == tagID {
                        return sub
                    }
                }
            }
        }
        return nil
    }
    
    func getFatherTag(tagID:UInt8)->Tag? {
        if tagID == 0 || tagID == 1 {
            return nil
        }
        for tag in m_tags {
            if tag.m_tagID == tagID {
                return nil
            }
            for sub in tag.m_subTags {
                if sub.m_tagID == tagID {
                    return tag
                }
            }
        }
        return nil
    }
    
    func remTag(tagID: UInt8) {
        for mainTag in m_tags {
            for (j, subTag) in mainTag.m_subTags.enumerate() {
                if subTag.m_tagID == tagID {
                    mainTag.m_subTags.removeAtIndex(j)
                    return
                }
            }
        }
    }
    
    func addContact(contact:ContactInfo) {
        if contact.isBlacklist() {
            m_blacklist.addMember(contact)
        }
        else {
            if contact.isUndefine() {
                m_undefine!.addMember(contact)
            }
            else {
                for tag in m_tags {
                    tag.addMember(contact)
                }
            }
            m_contacts[contact.user] = contact
        }
    }
    
    func addPossible(contact:ContactInfo) {
        m_possible?.m_members.append(contact.user)
        m_contacts[contact.user] = contact
    }
    
    func addStranger(contact:ContactInfo) {
        m_stranger?.m_members.append(contact.user)
        m_contacts[contact.user] = contact
    }
    
    func remContact(contactID:UInt64) {
        m_undefine!.remMember(contactID)
        for tag in m_tags {
            tag.remMember(contactID)
        }
        m_contacts.removeValueForKey(contactID)
    }
    
    func getContact(contactID:UInt64)->ContactInfo? {
        return m_contacts[contactID]
    }
    
    func moveContactInTag(contactID:UInt64, tagID:UInt8) {
        var contact = m_contacts[contactID]!
        let tag = getTag(tagID)!
        let father = getFatherTag(tagID)
        father?.remMember(contactID)
        if contact.isUndefine() {
            m_undefine!.remMember(contactID)
        }
        contact.flag |= (tag.m_bit | tag.m_fatherBit)
        tag.addMember(contact)
        m_contacts[contactID] = contact
    }
    
    func moveContactOutTag(contactID:UInt64, tagID:UInt8) {
        var contact = m_contacts[contactID]!
        let tag = getTag(tagID)!
        let father = getFatherTag(tagID)
        tag.remMember(contactID)
        contact.flag &= ~(tag.m_bit | tag.m_subBits)
        father?.addMember(contact)
        if contact.isUndefine() {
            m_undefine!.addMember(contact)
        }
        m_contacts[contactID] = contact
    }
    
    func loadContacts(contacts:Array<ContactInfo>, userTags:Array<TagInfo>) {
        m_tags.removeAll()
        
        // system tags
        initSystemTags()
        
        // load user tags
        for tagInfo in userTags {
            addSubTag(Tag(id: tagInfo.tagID, father: tagInfo.fatherID, name: tagInfo.tagName))
        }
        
        for contact in contacts {
            addContact(contact)
        }
    }
}
