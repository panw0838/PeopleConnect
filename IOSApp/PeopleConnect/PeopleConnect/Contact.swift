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
    
    init(id:UInt64, f:UInt64, n:String) {
        user = id
        flag = f
        name = n
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
        self.user = UInt64(user.intValue)
        self.flag = UInt64(flag.intValue)
        self.name = name
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
        self.tagID = UInt8(tagID.intValue)
        self.fatherID = UInt8(fatherID.intValue)
        self.tagName = tagName
    }
}

class Tag {
    var m_tagID: UInt8
    var m_fatherID: UInt8
    var m_bit: UInt64
    var m_fatherBit:UInt64
    var m_subBits: UInt64   // sons' bits
    var m_tagName: String
    var m_members: Array<ContactInfo>
    var m_subTags: Array<Tag>
    
    init(id: UInt8, father: UInt8, name: String) {
        m_tagID = id
        m_fatherID = father
        m_bit = (BitOne << UInt64(id))
        m_fatherBit = (father == 0 ? 0 : (BitOne << UInt64(father)))
        m_subBits = 0
        m_tagName = name
        m_members = Array<ContactInfo>()
        m_subTags = Array<Tag>()
    }
    
    func canBeDelete()->Bool {
        return ((m_bit & DefineTagMask) != 0)
            && (m_members.count == 0)
            && (m_subTags.count == 0)
    }
    
    func canBeEdit()->Bool {
        return (m_bit & UndefineBit) == 0
    }
    
    func addMember(contact: ContactInfo) {
        if (m_subBits & contact.flag) != 0 {
            for subTag in m_subTags {
                subTag.addMember(contact)
            }
        }
        else if (m_bit & contact.flag) != 0 {
            m_members.append(contact)
        }
    }
    
    func remMember(contactID: UInt64) {
        for subTag in m_subTags {
            subTag.remMember(contactID)
        }

        var i = 0
        for member in m_members {
            if contactID == member.user {
                m_members.removeAtIndex(i)
                return
            }
            i++
        }
    }
    
    func addSubTag(tag: Tag) {
        m_subTags.append(tag)
        m_subBits |= (BitOne << UInt64(tag.m_tagID))
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
    
    func getMembers()->Array<ContactInfo> {
        return m_members
    }
}

var contactsData:ContactsData = ContactsData()

class ContactsData {
    var m_blacklist: Tag = Tag(id: 0, father: 0, name: "黑名单")
    var m_undefine: Tag = Tag(id: 1, father: 0, name: "未分类")
    var m_tags: Array<Tag> = Array<Tag>()
    var m_contacts:Array<ContactInfo> = Array<ContactInfo>()

    init() {
        m_tags.removeAll()
        initSystemTags()
    }
    
    func initSystemTags() {
        m_blacklist.m_members.removeAll()
        m_undefine.m_members.removeAll()
        // system tags
        addTag(Tag(id: 2, father: 0, name: "家人"))
        addTag(Tag(id: 3, father: 0, name: "同学"))
        addTag(Tag(id: 4, father: 0, name: "同事"))
        addTag(Tag(id: 5, father: 0, name: "朋友"))
    }
    
    func numMainTags()->Int {
        return m_tags.count + 1
    }
    
    func getMainTag(idx:Int)->Tag {
        return idx == m_tags.count ? m_undefine : m_tags[idx]
    }
    
    func numSubTags(idx:Int)->Int {
        let tag = getMainTag(idx)
        return tag.m_subTags.count + 1
    }

    func getSubTag(mainIdx:Int, subIdx:Int)->Tag {
        if mainIdx == m_tags.count {
            return m_undefine
        }
        else {
            let tag = m_tags[mainIdx]
            if subIdx == tag.m_subTags.count {
                return tag
            }
            else {
                return tag.m_subTags[subIdx]
            }
        }
    }
    
    func addTag(newTag: Tag) {
        if (newTag.m_tagID == 0) {
            m_blacklist = newTag
        }
        else if (newTag.m_fatherID == 0) {
            m_tags.append(newTag)
        }
        else {
            let fatherTag: Tag = getTag(newTag.m_fatherID)!
            fatherTag.addSubTag(newTag)
        }
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
        for (i, tag) in m_tags.enumerate() {
            if tag.m_tagID == tagID {
                m_tags.removeAtIndex(i)
                return
            }
            for (j, subTag) in tag.m_subTags.enumerate() {
                if subTag.m_tagID == tagID {
                    tag.m_subTags.removeAtIndex(j)
                    return
                }
            }
        }
    }
    
    func addContact(contact:ContactInfo) {
        if contact.isBlacklist() {
            m_blacklist.addMember(contact)
        }
        else if contact.isUndefine() {
            m_undefine.addMember(contact)
            m_contacts.append(contact)
        }
        else {
            for tag in m_tags {
                tag.addMember(contact)
            }
            m_contacts.append(contact)
        }
    }
    
    func remContact(contactID:UInt64) {
        m_undefine.remMember(contactID)
        for tag in m_tags {
            tag.remMember(contactID)
        }
        for (idx, contact) in m_contacts.enumerate() {
            if contact.user == contactID {
                m_contacts.removeAtIndex(idx)
                break
            }
        }
    }
    
    func popContact(contactID:UInt64)->ContactInfo? {
        for (idx, contact) in m_contacts.enumerate() {
            if contact.user == contactID {
                m_contacts.removeAtIndex(idx)
                return contact
            }
        }
        return nil
    }
    
    func moveContactInTag(contactID:UInt64, tagID:UInt8) {
        var contact = popContact(contactID)!
        let tag = getTag(tagID)!
        let father = getFatherTag(tagID)
        father?.remMember(contactID)
        if contact.isUndefine() {
            m_undefine.remMember(contactID)
        }
        contact.flag |= (tag.m_bit | tag.m_fatherBit)
        tag.addMember(contact)
        m_contacts.append(contact)
    }
    
    func moveContactOutTag(contactID:UInt64, tagID:UInt8) {
        var contact = popContact(contactID)!
        let tag = getTag(tagID)!
        let father = getFatherTag(tagID)
        contact.flag &= ~(tag.m_bit | tag.m_subBits)
        tag.remMember(contactID)
        father?.addMember(contact)
        if contact.isUndefine() {
            m_undefine.addMember(contact)
        }
        m_contacts.append(contact)
    }
    
    func loadContacts(contacts:Array<ContactInfo>, userTags:Array<TagInfo>) {
        m_tags.removeAll()
        
        // system tags
        initSystemTags()
        
        // load user tags
        for tagInfo in userTags {
            addTag(Tag(id: tagInfo.tagID, father: tagInfo.fatherID, name: tagInfo.tagName))
        }
        
        for contact in contacts {
            addContact(contact)
        }
    }
}
