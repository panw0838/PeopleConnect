//
//  View+Tags.swift
//  PeopleConnect
//
//  Created by apple on 18/12/31.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

let TagColors = [
    1:UIColor(red: 178.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 1.0),
    2:UIColor(red: 34.0/255.0, green: 193.0/255.0, blue: 34.0/255.0, alpha: 1.0),
    3:UIColor(red: 0.0, green: 139.0/255.0, blue: 139.0/255.0, alpha: 1.0),
    4:UIColor(red: 139.0/255.0, green: 0.0, blue: 139.0/255.0, alpha: 1.0),
    5:UIColor(red: 139.0/255.0, green: 139.0/255.0, blue: 0.0, alpha: 1.0)]

let GroupColors = [
    UIColor(red: 34.0/255.0, green: 178.0/255.0, blue: 34.0/255.0, alpha: 1.0),
    UIColor(red: 34.0/255.0, green: 34.0/255.0, blue: 178.0/255.0, alpha: 1.0)]

let nearColor = UIColor(red: 199.0/255.0, green: 21.0/255.0, blue: 133.0/255.0, alpha: 1.0)

let tagEditFont = UIFont.systemFontOfSize(16)

let PostTagHeight:CGFloat = 15
let PostTagSpace:CGFloat = 15

let EditTagExWidth:CGFloat = 20
let EditTagHeight:CGFloat = 30
let EditTagSpace:CGFloat = 10
let EditTagLineSpace:CGFloat = 8

extension Post {
    func getPermitHeight(width:CGFloat)->CGFloat {
        var numLines = 1
        var lineEnd:CGFloat = 0
        
        let tags = getPermitTags()
        
        for tag in tags {
            let tagWidth = getTextWidth(tag.m_tagName, height: PostTagHeight, font: statusFont) + PostTagSpace
            
            if tagWidth + lineEnd > width {
                numLines++
                lineEnd = 0
            }
            
            lineEnd += (tagWidth + PostItemGap)
        }
        
        if m_info.near {
            let tagWidth = getTextWidth("附近", height: PostTagHeight, font: statusFont) + PostTagSpace
            
            if tagWidth + lineEnd > width {
                numLines++
                lineEnd = 0
            }
            lineEnd += (tagWidth + PostItemGap)
        }
        
        for group in m_info.groups {
            let tagWidth = getTextWidth(group, height: PostTagHeight, font: statusFont) + PostTagSpace
            
            if tagWidth + lineEnd > width {
                numLines++
                lineEnd = 0
            }
            
            lineEnd += (tagWidth + PostItemGap)
        }
        
        return CGFloat(numLines) * PostTagHeight + CGFloat(numLines-1) * PostPreViewGap
    }
}

extension ContactsData {
    func getTagsHeight(width:CGFloat)->CGFloat {
        var numLines = 1
        var lineEnd:CGFloat = 0
        let tags = contactsData.getContactTags()
        
        for tag in tags {
            let tagWidth = getTextWidth(tag.m_tagName, height: EditTagHeight, font: tagEditFont) + EditTagExWidth
            
            if tagWidth + lineEnd > width {
                numLines++
                lineEnd = 0
            }
            
            lineEnd += (tagWidth + EditTagSpace)
        }
        
        return CGFloat(numLines) * EditTagHeight + CGFloat(numLines-1) * EditTagLineSpace
    }
}

extension UserInfo {
    func getGroupsHeight(width:CGFloat)->CGFloat {
        var numLines = 1
        var lineEnd:CGFloat = 0
        
        for group in groups {
            let groupWidth = getTextWidth(group.name, height: EditTagHeight, font: tagEditFont) + EditTagExWidth
            
            if groupWidth + lineEnd > width {
                numLines++
                lineEnd = 0
            }
            
            lineEnd += (groupWidth + EditTagSpace)
        }
        
        return CGFloat(numLines) * EditTagHeight + CGFloat(numLines-1) * EditTagLineSpace
    }
}

class TagLabel:UILabel {
    var m_data:UInt64 = 0
    var m_hilighted = false
    var m_hilightColor = UIColor.clearColor()
    var m_father:TagsView? = nil
    
    func tap() {
        m_hilighted = !m_hilighted
        if m_hilighted {
            backgroundColor = m_hilightColor
            m_father?.m_selected.insert(m_data)
        }
        else {
            backgroundColor = UIColor.grayColor()
            m_father?.m_selected.remove(m_data)
        }
        m_father!.m_controller!.updateCreateBtn()
    }
}

class TagsView: UIView {
    let MaxTags = 64
    var m_tagLabels = Array<TagLabel>()
    // for edit
    var m_controller:CreatePostView? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubViews(false)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initSubViews(true)
    }
    
    func initSubViews(edit:Bool) {
        for _ in 0...MaxTags-1 {
            let tag = TagLabel(frame: CGRectZero)
            tag.font = edit ? tagEditFont : statusFont
            tag.layer.cornerRadius = 8
            tag.layer.masksToBounds = true
            tag.hidden = true
            tag.textAlignment = .Center
            tag.textColor = UIColor.whiteColor()
            tag.m_father = self

            if edit {
                let tap = UITapGestureRecognizer(target: tag, action: Selector("tap"))
                tag.userInteractionEnabled = true
                tag.addGestureRecognizer(tap)
            }
            
            m_tagLabels.append(tag)
            addSubview(tag)
        }
    }
    
    var m_curTag = 0
    var m_numLines = 0
    var m_lineEnd:CGFloat = 0
    var m_width:CGFloat = 0
    
    var m_selected = Set<UInt64>()
    
    func getFlag()->UInt64 {
        var flag:UInt64 = 0
        for item in m_selected {
            flag |= item
        }
        return flag
    }
    
    func getGroups()->Array<String> {
        var groups = Array<String>()
        for item in m_selected {
            groups.append(userInfo.groups[Int(item)].name)
        }
        return groups
    }
    
    func pushEditTag(name:String, data:UInt64, color:UIColor) {
        let tagWidth = getTextWidth(name, height: EditTagHeight, font: tagEditFont) + EditTagExWidth
        let tagLabel = m_tagLabels[m_curTag]
        
        if tagWidth + m_lineEnd > m_width {
            m_numLines++
            m_lineEnd = 0
        }
        
        tagLabel.m_data = data
        tagLabel.hidden = false
        tagLabel.text = name
        tagLabel.backgroundColor = UIColor.grayColor()
        tagLabel.m_hilightColor = color
        tagLabel.frame = CGRectMake(m_lineEnd, CGFloat(m_numLines)*(EditTagHeight+EditTagLineSpace), tagWidth, EditTagHeight)
        
        m_lineEnd += (tagWidth + EditTagSpace)
        m_curTag++
    }
    
    func loadUserGroups(width:CGFloat) {
        for label in m_tagLabels {
            label.hidden = true
        }
        
        m_curTag = 0
        m_numLines = 0
        m_lineEnd = 0
        m_width = width
        
        for (i, group) in userInfo.groups.enumerate() {
            let color = GroupColors[i]
            pushEditTag(group.name, data: UInt64(i), color: color)
        }
    }
    
    func loadContactTags(width:CGFloat) {
        for label in m_tagLabels {
            label.hidden = true
        }
        
        m_curTag = 0
        m_numLines = 0
        m_lineEnd = 0
        m_width = width

        let tags = contactsData.getContactTags()
        
        for tag in tags {
            let colorTagID = (tag.m_father != nil ? tag.m_father?.m_tagID : tag.m_tagID)
            let color = TagColors[Int(colorTagID!)]
            pushEditTag(tag.m_tagName, data: tag.m_bit, color: color!)
        }
        // init to contacts bit
        m_tagLabels[m_curTag-1].m_hilighted = true
        m_tagLabels[m_curTag-1].backgroundColor = m_tagLabels[m_curTag-1].m_hilightColor
        m_selected.insert(contactsData.m_undefine.m_bit)
    }
    
    func pushTag(name:String, color:UIColor) {
        let tagWidth = getTextWidth(name, height: PostTagHeight, font: statusFont) + PostTagSpace
        let tagLabel = m_tagLabels[m_curTag]
        
        if tagWidth + m_lineEnd > m_width {
            m_numLines++
            m_lineEnd = 0
        }
        
        tagLabel.hidden = false
        tagLabel.text = name
        tagLabel.backgroundColor = color
        tagLabel.frame = CGRectMake(m_lineEnd, CGFloat(m_numLines)*(PostTagHeight+PostTagSpace), tagWidth, PostTagHeight)
        
        m_lineEnd += (tagWidth + PostItemGap)
        m_curTag++
    }
    
    func load(post:Post, width:CGFloat) {
        for label in m_tagLabels {
            label.hidden = true
        }
        
        m_curTag = 0
        m_numLines = 0
        m_lineEnd = 0
        m_width = width
        
        let tags = post.getPermitTags()
        for tag in tags {
            let fatherTagID = (tag.m_father != nil ? tag.m_father?.m_tagID : tag.m_tagID)
            let color = TagColors[Int(fatherTagID!)]
            pushTag(tag.m_tagName, color: color!)
        }
        
        if post.m_info.near {
            pushTag("附近", color: nearColor)
        }

        for group in post.m_info.groups {
            let color = getGroupColor(group)
            pushTag(group, color: color)
        }
    }
}