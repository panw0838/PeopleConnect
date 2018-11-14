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
}

extension ContactInfo {
    init?(json: [String: AnyObject]) {
        guard
            let user = json["user"] as? UInt64,
            let flag = json["flag"] as? UInt64,
            let name = json["name"] as? String
        else {
            return nil
        }
        self.user = user
        self.flag = flag
        self.name = name
    }
}

let BitOne: UInt64 = 0x1
let BlacklistBit: UInt64 = 0x1
let SystemTagStart: UInt64 = 0x1
let SystemTagEnd: UInt64 = 0x20
let DefineTagStart: UInt64 = 0x100000000
let DefineTagEnd: UInt64 = 0x8000000000000000
let DefineTagMask: UInt64 = 0xFFFFFFFF00000000

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
    var tagID: UInt8
    var fatherID: UInt8
    var subBits: UInt64
    var tagName: String
    var members: Array<ContactInfo>
    var subTags: Array<Tag>
    
    init(id: UInt8, father: UInt8, name: String) {
        tagID = id
        fatherID = father
        subBits = 0
        tagName = name
        members = Array<ContactInfo>()
        subTags = Array<Tag>()
    }
    
    func addMember(contact: ContactInfo) {
        if (subBits == 0 || (subBits | contact.flag) == 0) {
            members.append(contact)
        }
    }
    
    func addSubTag(tag: Tag) {
        subTags.append(tag)
        subBits |= (BitOne << UInt64(tag.tagID))
    }
    
    func getNumSubTags()->Int {
        return subTags.count
    }
    
    func getSubTagName(subIdx: Int)->String {
        return subTags[subIdx].tagName
    }
    
    func getMembers()->Array<ContactInfo> {
        return members
    }
}

var contacts:Array<ContactInfo> = Array<ContactInfo>()
var userTags:Array<TagInfo> = Array<TagInfo>()
var contactsData:ContactsData = ContactsData()

class ContactsData {
    var m_blacklist: Tag = Tag(id: 0, father: 0, name: "黑名单")
    var m_tags: Array<Tag> = Array<Tag>()
    var m_tagsDic: Dictionary<UInt8,Tag> = [:]
    
    init() {
    }
    
    func numMainTags()->Int {
        return m_tags.count
    }
    
    func nameOfMainTag(tagIdx: Int)->String {
        return m_tags[tagIdx].tagName
    }
    
    func numSubTags(tagIdx: Int)->Int {
        let tag:Tag = m_tags[tagIdx]
        return tag.getNumSubTags()
    }
    
    func nameOfSubTag(tagIdx: Int, subIdx: Int)->String {
        let tag:Tag = m_tags[tagIdx]
        return tag.getSubTagName(subIdx)
    }
    
    func membersOfMainTag(tagIdx: Int)->Array<ContactInfo> {
        return m_tags[tagIdx].getMembers()
    }
    
    func membersOfSubTag(tagIdx: Int, subIdx: Int)->Array<ContactInfo> {
        let tag:Tag = m_tags[tagIdx]
        let subTag:Tag = tag.subTags[subIdx]
        return subTag.getMembers()
    }
    
    func addTag(tag: Tag) {
        if (tag.tagID == 0) {
            m_blacklist = tag
        }
        else if (tag.fatherID == 0) {
            m_tags.append(tag)
        }
        else {
            let tag: Tag = getTag(tag.fatherID)
            tag.addSubTag(tag)
        }
        m_tagsDic[tag.tagID] = tag
    }
    
    func getTag(tagID: UInt8)->Tag {
        return m_tagsDic[tagID]!
    }
    
    func getContactTags(flag: UInt64)->Array<UInt8> {
        var tags: Array<UInt8> = Array<UInt8>()
        // check system tags
        for var id:UInt8 = 0; id <= 5; id++ {
            let bit: UInt64 = BitOne << UInt64(id)
            if (flag & bit != 0) {
                tags.append(id)
            }
        }
        // check define tags
        if (flag & DefineTagMask != 0) {
            for var id:UInt8 = 32; id <= 63; id++ {
                let bit: UInt64 = BitOne << UInt64(id)
                if (flag & bit != 0) {
                    tags.append(id)
                }
            }
        }
        return tags
    }
    
    func loadContacts() {
        m_tags.removeAll()
        m_tagsDic.removeAll()
        // system tags
        addTag(Tag(id: 0, father: 0, name: "黑名单"))
        addTag(Tag(id: 1, father: 0, name: "家人"))
        addTag(Tag(id: 2, father: 0, name: "同学"))
        addTag(Tag(id: 3, father: 0, name: "同事"))
        addTag(Tag(id: 4, father: 0, name: "朋友"))
        addTag(Tag(id: 5, father: 0, name: "联系人"))
        // load user tags
        for tagInfo in userTags {
            addTag(Tag(id: tagInfo.tagID, father: tagInfo.fatherID, name: tagInfo.tagName))
        }
        
        for contact in contacts {
            let tagsID: Array<UInt8> = getContactTags(contact.flag)
            for tagID in tagsID {
                let tag: Tag = getTag(tagID)
                tag.addMember(contact)
            }
        }
    }
}
