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

enum StrangerTag:UInt8 {
    case ActionsTag   = 0xff
    case CellUsersTag = 0xfe
    case ConnUsersTag = 0xfd
    case FaceUsersTag = 0xfc
    case LikeUsersTag = 0xfb
    case NearUsersTag = 0xfa
}

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


var contactsData:ContactsData = ContactsData()

class ContactsData {
    var m_blacklist  = Tag(id: 0, father: 0, name: "黑名单")
    var m_undefine   = Tag(id: 1, father: 0, name: "联系人")

    var m_cellUsers = Tag(id: StrangerTag.CellUsersTag.rawValue, father: 0, name: "手机通讯录")
    var m_rcmtUsers = Tag(id: StrangerTag.ConnUsersTag.rawValue, father: 0, name: "推荐联系人")
    var m_faceUsers = Tag(id: StrangerTag.FaceUsersTag.rawValue, father: 0, name: "面对面加好友")
    var m_likeUsers = Tag(id: StrangerTag.LikeUsersTag.rawValue, father: 0, name: "互赞的陌生人")
    var m_nearUsers = Tag(id: StrangerTag.NearUsersTag.rawValue, father: 0, name: "附近的陌生人")

    var m_strangerActTag = Tag(id: StrangerTag.ActionsTag.rawValue, father: 0, name: "搜索新朋友")
    var m_strangerTags = Array<Tag>()
    
    var m_contactTags = Array<Tag>()
    var m_delegate:ContactDataDelegate?
    
    var m_users = Dictionary<UInt64, ContactInfo>()
    var m_missNameUsers = Array<UInt64>()
    var m_missPhotoUsers = Array<UInt64>()
    
    func addUser(uID:UInt64, name:String, flag:UInt64) {
        if m_users[uID] == nil {
            m_users[uID] = ContactInfo(id: uID, f: flag, n: name)
            if name.characters.count == 0 {
                m_missNameUsers.append(uID)
            }
        }
        else if name.characters.count > 0 || flag != 0 {
            // update info
            m_users[uID] = ContactInfo(id: uID, f: flag, n: name)
        }
        
        if getContactPhoto(uID) == nil {
            m_missPhotoUsers.append(uID)
        }
    }
    
    func addUser(info:ContactInfo) {
        m_users[info.user] = info
        if info.name.characters.count == 0 {
            m_missNameUsers.append(info.user)
        }
        if getContactPhoto(info.user) == nil {
            m_missPhotoUsers.append(info.user)
        }
    }

    func getUser(uID:UInt64)->ContactInfo? {
        return m_users[uID]
    }

    init() {
        // system tags
        m_contactTags.append(Tag(id: 2, father: 0, name: "家人"))
        m_contactTags.append(Tag(id: 3, father: 0, name: "同学"))
        m_contactTags.append(Tag(id: 4, father: 0, name: "同事"))
        m_contactTags.append(Tag(id: 5, father: 0, name: "朋友"))
        
        m_strangerActTag.m_actions.append(.SearchCell)
        m_strangerActTag.m_actions.append(.SearchConn)
        m_strangerActTag.m_actions.append(.SearchFace)
        m_strangerActTag.m_actions.append(.SearchLike)
        m_strangerActTag.m_actions.append(.SearchNear)
        m_strangerTags.append(m_strangerActTag)
    }
    
    func updateStrangerTags(tag:Tag) {
        var newTags = Array<Tag>()
        newTags.append(m_strangerActTag)
        
        if tag.m_members.count > 0 {
            newTags.append(tag)
        }
        
        for oldTag in m_strangerTags {
            if oldTag.m_tagID != StrangerTag.ActionsTag.rawValue && oldTag.m_tagID != tag.m_tagID {
                newTags.append(oldTag)
            }
        }
        
        m_strangerTags = newTags
        updateDelegates()
    }
    
    func setDelegate(delegate:ContactDataDelegate?) {
        m_delegate = delegate
    }
    
    func updateDelegates() {
        m_delegate?.ContactDataUpdate()
    }
    
    func getContactTags()->Array<Tag> {
        var tags = Array<Tag>()
        for tag in m_contactTags {
            tags.append(tag)
            for subTag in tag.m_subTags {
                tags.append(subTag)
            }
        }
        tags.append(m_undefine)
        return tags
    }
    
    func getUsers(passed:(()->Void)?, failed:((err:String?)->Void)?) {
        if m_missNameUsers.count > 0 {
            httpGetUsers(m_missNameUsers,
                passed: {()->Void in
                    passed?()
                },
                failed: {(err:String?)->Void in
                    failed?(err: err)
                })
        }
        if m_missPhotoUsers.count > 0 {
            httpGetPhotos(m_missPhotoUsers,
                passed: {()->Void in
                    passed?()
                },
                failed: {(err:String?)->Void in
                    failed?(err: err)
                })
        }
    }
    
    func numMainTags()->Int {
        return m_contactTags.count + 2
    }
    
    func numSubTags(idx:Int)->Int {
        if idx < m_contactTags.count {
            return (m_contactTags[idx].m_subTags.count + 1)
        }
        else if idx == m_contactTags.count {
            return 1
        }
        else {
            return m_strangerTags.count
        }
    }

    func getSubTag(idx:Int, subIdx:Int)->Tag {
        if idx < m_contactTags.count {
            let tag = m_contactTags[idx]
            if subIdx == tag.m_subTags.count {
                return tag
            }
            else {
                return tag.m_subTags[subIdx]
            }
        }
        else if idx == m_contactTags.count {
            return m_undefine
        }
        else {
            return m_strangerTags[subIdx]
        }
    }
    
    func addSubTag(newTag: Tag) {
        let fatherTag: Tag = m_contactTags[Int(newTag.m_fatherID) - 2]
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
            for tag in m_contactTags {
                tag.addMember(contact)
            }
        }
        addUser(contact)
    }
    
    func remContact(contactID:UInt64) {
        m_undefine.remMember(contactID, inSubTags: true)
        for tag in m_contactTags {
            tag.remMember(contactID, inSubTags: true)
        }
        var info = m_users[contactID]
        if info != nil {
            info?.flag = 0
            m_users[contactID] = info
        }
    }
    
    func getContact(contactID:UInt64)->ContactInfo? {
        return m_users[contactID]
    }
    
    func moveContactsInTag(cIDs:Array<UInt64>, tag:Tag) {
        for cID in cIDs {
            var contact = m_users[cID]!
            tag.m_father?.remMember(cID, inSubTags: false)
            if contact.isUndefine() {
                m_undefine.remMember(cID, inSubTags: false)
            }
            contact.flag |= (tag.m_bit | tag.m_fatherBit)
            tag.addMember(contact)
            m_users[cID] = contact
        }
    }
    
    func moveContactsOutTag(cIDs:Array<UInt64>, tag:Tag) {
        for cID in cIDs {
            var contact = m_users[cID]!
            tag.remMember(cID, inSubTags: true)
            contact.flag &= ~(tag.m_bit | tag.m_subBits)
            tag.m_father?.addMember(contact)
            if contact.isUndefine() {
                m_undefine.addMember(contact)
            }
            m_users[cID] = contact
        }
    }
    
    func clearContacts() {
        for tag in m_contactTags {
            tag.clearContacts()
        }
        
        m_undefine.clearContacts()
    }
}
