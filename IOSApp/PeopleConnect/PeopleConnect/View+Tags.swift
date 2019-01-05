//
//  View+Tags.swift
//  PeopleConnect
//
//  Created by apple on 18/12/31.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import UIKit

let TagColors = [
    1:UIColor.redColor(),
    2:UIColor.greenColor(),
    3:UIColor.blueColor(),
    4:UIColor.yellowColor(),
    5:UIColor.purpleColor()]

let tagEditFont = UIFont.systemFontOfSize(15)

let PostTagHeight:CGFloat = 15
let PostTagSpace:CGFloat = 15

let EditTagExWidth:CGFloat = 20
let EditTagHeight:CGFloat = 30
let EditTagSpace:CGFloat = 10
let EditTagLineSpace:CGFloat = 20

extension Post {
    func getPermitHeight(width:CGFloat)->CGFloat {
        var numLines = 1
        var lineEnd:CGFloat = 0
        
        let tags = getPermitTags()
        
        for tag in tags {
            let tagWidth = getTextWidth(tag.m_tagName, height: 10, font: statusFont) + PostTagSpace
            
            if tagWidth + lineEnd > width {
                numLines++
                lineEnd = 0
            }
            
            lineEnd += (tagWidth + PostItemGap)
        }
        
        if m_info.near {
            let tagWidth = getTextWidth("附近", height: 10, font: statusFont) + PostTagSpace
            
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
        let tags = contactsData.getPostTags()
        
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

class TagLabel:UILabel {
    var m_data:UInt64 = 0
    var m_hilighted = false
    var m_hilightColor = UIColor.clearColor()
    var m_father:TagsView? = nil
    
    func tap() {
        m_hilighted = !m_hilighted
        if m_hilighted {
            backgroundColor = m_hilightColor
            m_father?.m_flag |= m_data
        }
        else {
            backgroundColor = UIColor.grayColor()
            m_father?.m_flag &= ~m_data
        }
    }
}

class TagsView: UIView {
    let MaxTags = 64
    var m_tags = Array<TagLabel>()
    
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
            let tap = UITapGestureRecognizer(target: tag, action: Selector("tap"))
            tag.userInteractionEnabled = true
            tag.addGestureRecognizer(tap)
            tag.font = edit ? tagEditFont : statusFont
            tag.layer.cornerRadius = 8
            tag.layer.masksToBounds = true
            tag.hidden = true
            tag.textAlignment = .Center
            tag.textColor = UIColor.whiteColor()
            tag.m_father = self
            m_tags.append(tag)
            addSubview(tag)
        }
    }
    
    var m_curTag = 0
    var m_numLines = 0
    var m_lineEnd:CGFloat = 0
    var m_width:CGFloat = 0
    
    var m_flag:UInt64 = 0
    
    func pushTag(tag:Tag, font:UIFont) {
        let colorTagID = (tag.m_father != nil ? tag.m_father?.m_tagID : tag.m_tagID)
        let color = TagColors[Int(colorTagID!)]
        let tagWidth = getTextWidth(tag.m_tagName, height: EditTagHeight, font: font) + EditTagExWidth
        let tagLabel = m_tags[m_curTag]
        
        if tagWidth + m_lineEnd > m_width {
            m_numLines++
            m_lineEnd = 0
        }
        
        tagLabel.m_data = tag.m_bit
        tagLabel.hidden = false
        tagLabel.text = tag.m_tagName
        tagLabel.backgroundColor = UIColor.grayColor()
        tagLabel.m_hilightColor = color!
        tagLabel.frame = CGRectMake(m_lineEnd, CGFloat(m_numLines)*(EditTagHeight+EditTagLineSpace), tagWidth, EditTagHeight)
        
        m_lineEnd += (tagWidth + EditTagSpace)
        m_curTag++
    }
    
    func loadContactTags(width:CGFloat) {
        for tag in m_tags {
            tag.hidden = true
        }
        
        m_curTag = 0
        m_numLines = 0
        m_lineEnd = 0
        m_width = width

        let tags = contactsData.getPostTags()
        
        for (_, tag) in tags.enumerate() {
            pushTag(tag, font: tagEditFont)
        }
    }
    
    func load(post:Post, width:CGFloat) {
        for tag in m_tags {
            tag.hidden = true
        }
        
        var numLines = 0
        var lineEnd:CGFloat = 0
        let tags = post.getPermitTags()
        
        for (idx, tag) in tags.enumerate() {
            let tagWidth = getTextWidth(tag.m_tagName, height: 10, font: statusFont) + PostTagSpace
            let tagLabel = m_tags[idx]
            
            if tagWidth + lineEnd > width {
                numLines++
                lineEnd = 0
            }
            
            tagLabel.hidden = false
            tagLabel.frame = CGRectMake(lineEnd, CGFloat(numLines)*(PostTagHeight+PostPreViewGap), tagWidth, PostTagHeight)
            tagLabel.text = tag.m_tagName
            
            let fatherTagID = (tag.m_father != nil ? tag.m_father?.m_tagID : tag.m_tagID)
            tagLabel.backgroundColor = TagColors[Int(fatherTagID!)]
            
            lineEnd += (tagWidth + PostItemGap)
        }
        
        var tagIdx = tags.count
        
        if post.m_info.near {
            let tagWidth = getTextWidth("附近", height: 10, font: statusFont) + PostTagSpace
            let tagLabel = m_tags[tagIdx]
            
            if tagWidth + lineEnd > width {
                numLines++
                lineEnd = 0
            }

            tagLabel.hidden = false
            tagLabel.frame = CGRectMake(lineEnd, CGFloat(numLines)*(PostTagHeight+PostPreViewGap), tagWidth, PostTagHeight)
            tagLabel.text = "附近"
            tagLabel.backgroundColor = UIColor.cyanColor()

            lineEnd += (tagWidth + PostItemGap)
            tagIdx++
        }

        // for groups
    }
}
