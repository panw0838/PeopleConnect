//
//  Data+Tag.swift
//  PeopleConnect
//
//  Created by apple on 19/1/7.
//  Copyright © 2019年 Pan's studio. All rights reserved.
//

import Foundation

enum TagAction {
    case MoveMember
    case DelTag
    case AddTag
    
    case SearchCell
    case SearchConn
    case SearchFace
    case SearchLike
    case SearchNear
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
    var m_actions = Array<TagAction>()
    
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
    
    func isSysTag()->Bool {
        return isContactTag() && m_fatherID == 0
    }
    
    func isUserTag()->Bool {
        return (m_fatherID != 0)
    }
    
    func isStrangerTag()->Bool {
        return m_bit == 0
    }
    
    func canBeDelete()->Bool {
        return isUserTag() && (m_members.count == 0)
    }
    
    func isContactTag()->Bool {
        return (m_bit & GroupMask) != 0
    }
    
    func addMember(contact: ContactInfo) {
        if m_bit != 0 && (m_subBits & contact.flag) != 0 {
            // add to sub tags
            for subTag in m_subTags {
                subTag.addMember(contact)
            }
        }
        else if m_bit == 0 && contact.flag == 0 || (m_bit & contact.flag) != 0 && (m_subBits & contact.flag) == 0 {
            // add to self if stranger or no sub tags
            var exists = false
            for member in m_members {
                if member == contact.user {
                    exists = true
                }
            }
            if !exists {
                m_members.append(contact.user)
            }
        }
    }
    
    func remMember(contactID: UInt64, inSubTags:Bool) {
        if inSubTags {
            for subTag in m_subTags {
                subTag.remMember(contactID, inSubTags: inSubTags)
            }
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
    
    func reloadActions(edit:Bool) {
        // only contact tag need reload
        if isSysTag() {
            m_actions.removeAll()
            if edit {
                m_actions.append(.MoveMember)
                m_actions.append(.AddTag)
            }
        }
        else if isUserTag() {
            m_actions.removeAll()
            if edit {
                m_actions.append(.MoveMember)
                if canBeDelete() {
                    m_actions.append(.DelTag)
                }
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
