//
//  Contact.swift
//  PeopleConnect
//
//  Created by apple on 18/11/11.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation

let BitOne:         UInt64 = 0x1
let BlacklistBit:   UInt64 = 0x100000000
let UndefineBit:    UInt64 = 0x200000000
let UserTagMask:    UInt64 = 0xFFFFFFFF
let RelateTagMask:  UInt64 = (UserTagMask | 0x3E00000000)
let GroupMask:      UInt64 = (UserTagMask | 0x3C00000000)
let PossibleTag:    UInt8  = 0xFE
let StrangerTag:    UInt8  = 0xFF
let SysTagOffset:   UInt64 = 32

protocol ContactDataDelegate {
    func ContactDataUpdate()->Void
}

struct ContactInfo {
    var user: UInt64 = 0
    var flag: UInt64 = 0
    var name: String = ""
    var ip: String = ""
    var x: Double = 0
    var y: Double = 0
    var numConn: UInt32 = 0
    
    init(id:UInt64, f:UInt64, n:String) {
        user = id
        flag = f
        name = n
    }
    
    func isBlacklist()->Bool {
        return (flag & BlacklistBit) == BlacklistBit
    }
    
    func isUndefine()->Bool {
        return ((flag & RelateTagMask) == UndefineBit) && !isBlacklist()
    }
    
    func isContact()->Bool {
        return ((flag & RelateTagMask) != 0) && !isBlacklist()
    }
}

extension ContactInfo {
    init?(json: [String: AnyObject]) {
        guard
            let user = json["user"] as? NSNumber,
            let name = json["name"] as? String
        else {
            return nil
        }
        self.user = UInt64(user.unsignedLongLongValue)
        self.name = name
        
        let flag = json["flag"] as? NSNumber
        self.flag = (flag != nil ? UInt64(flag!.unsignedLongLongValue) : 0)
        
        let x = json["x"] as? NSNumber
        self.x = (x != nil ? Double(x!.doubleValue) : 0)
        let y = json["y"] as? NSNumber
        self.y = (y != nil ? Double(y!.doubleValue) : 0)
        
        let numConn = json["conn"] as? NSNumber
        self.numConn = (numConn != nil ? UInt32(numConn!.unsignedIntValue) : 0)
    }
}

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
    var m_father:Tag? = nil
    var m_subTags: Array<Tag> = Array<Tag>()
    
    init(id: UInt8, father: UInt8, name: String) {
        m_tagID = id
        m_fatherID = father
        m_tagName = name
        
        if father != 0 {
            m_bit = (BitOne << UInt64(id))
            m_fatherBit = (BitOne << (UInt64(father) + SysTagOffset))
        }
        else if (id & 0x80) == 0 {
            m_bit = (BitOne << (UInt64(id) + SysTagOffset))
        }
    }
    
    func clearContacts() {
        m_members.removeAll()
        for subTag in m_subTags {
            subTag.clearContacts()
        }
    }
    
    func isUserTag()->Bool {
        return (m_fatherID != 0)
    }
    
    func canBeDelete()->Bool {
        return isUserTag() && (m_members.count == 0)
    }
    
    func canBeEdit()->Bool {
        return (m_bit & GroupMask) != 0
    }
    
    func isStrangerTag()->Bool {
        return (m_bit == 0)
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
        tag.m_father = self
        m_subTags.append(tag)
        m_subBits |= tag.m_bit
    }
    
    func remSubTag(tag: Tag) {
        for (idx, subTag) in m_subTags.enumerate() {
            if subTag.m_tagID == tag.m_tagID {
                m_subTags.removeAtIndex(idx)
                m_subBits &= ~subTag.m_bit
                break
            }
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
    var m_blacklist = Tag(id: 0, father: 0, name: "黑名单")
    var m_undefine = Tag(id: 1, father: 0, name: "联系人")
    var m_possible = Tag(id: PossibleTag, father: 0, name: "可能认识的人")
    var m_stranger = Tag(id: StrangerTag, father: 0, name: "附近的陌生人")
    var m_tags: Array<Tag> = Array<Tag>()
    var m_contacts = Dictionary<UInt64, ContactInfo>()
    var m_delegates = Array<ContactDataDelegate>()

    init() {
        // system tags
        m_tags.append(Tag(id: 2, father: 0, name: "家人"))
        m_tags.append(Tag(id: 3, father: 0, name: "同学"))
        m_tags.append(Tag(id: 4, father: 0, name: "同事"))
        m_tags.append(Tag(id: 5, father: 0, name: "朋友"))
    }
    
    func updateDelegates() {
        for delegate in contactsData.m_delegates {
            delegate.ContactDataUpdate()
        }
    }
    
    func getPostTags()->Array<Tag> {
        var tags = Array<Tag>()
        for tag in m_tags {
            tags.append(tag)
            for subTag in tag.m_subTags {
                tags.append(subTag)
            }
        }
        tags.append(m_undefine)
        return tags
    }
    
    func getMissingPhotos()->Array<UInt64> {
        var ids = Array<UInt64>()
        for (_, contact) in m_contacts.enumerate() {
            if getContactPhoto(contact.0) == nil {
                ids.append(contact.0)
            }
        }
        return ids
    }
    
    func numMainTags()->Int {
        return m_tags.count + 2
    }
    
    func numSubTags(idx:Int)->Int {
        if idx < m_tags.count {
            return (m_tags[idx].m_subTags.count + 1)
        }
        else if idx == m_tags.count {
            return 1
        }
        else {
            return 2
        }
    }

    func getSubTag(idx:Int, subIdx:Int)->Tag {
        if idx < m_tags.count {
            let tag = m_tags[idx]
            if subIdx == tag.m_subTags.count {
                return tag
            }
            else {
                return tag.m_subTags[subIdx]
            }
        }
        else if idx == m_tags.count {
            return m_undefine
        }
        else {
            return subIdx == 0 ? m_possible : m_stranger
        }
    }
    
    func addSubTag(newTag: Tag) {
        let fatherTag: Tag = m_tags[Int(newTag.m_fatherID) - 2]
        fatherTag.addSubTag(newTag)
    }
    
    func addContact(contact:ContactInfo) {
        if contact.isBlacklist() {
            m_blacklist.addMember(contact)
        }
        else if contact.isUndefine() {
            m_undefine.addMember(contact)
        }
        else {
            for tag in m_tags {
                tag.addMember(contact)
            }
        }
        m_contacts[contact.user] = contact
    }
    
    func addUser(contact:ContactInfo) {
        m_contacts[contact.user] = contact
    }

    func remContact(contactID:UInt64) {
        m_undefine.remMember(contactID)
        for tag in m_tags {
            tag.remMember(contactID)
        }
        var info = m_contacts[contactID]
        if info != nil {
            info?.flag = 0
            m_contacts[contactID] = info
        }
    }
    
    func getContact(contactID:UInt64)->ContactInfo? {
        return m_contacts[contactID]
    }
    
    func moveContactsInTag(cIDs:Array<UInt64>, tag:Tag) {
        for cID in cIDs {
            var contact = m_contacts[cID]!
            tag.m_father?.remMember(cID)
            if contact.isUndefine() {
                m_undefine.remMember(cID)
            }
            contact.flag |= (tag.m_bit | tag.m_fatherBit)
            tag.addMember(contact)
            m_contacts[cID] = contact
        }
    }
    
    func moveContactsOutTag(cIDs:Array<UInt64>, tag:Tag) {
        for cID in cIDs {
            var contact = m_contacts[cID]!
            tag.remMember(cID)
            contact.flag &= ~(tag.m_bit | tag.m_subBits)
            tag.m_father?.addMember(contact)
            if contact.isUndefine() {
                m_undefine.addMember(contact)
            }
            m_contacts[cID] = contact
        }
    }
    
    func loadContacts(contacts:Array<ContactInfo>) {
        for tag in m_tags {
            tag.clearContacts()
        }
        
        m_undefine.clearContacts()
        
        for contact in contacts {
            addContact(contact)
        }
    }
}
