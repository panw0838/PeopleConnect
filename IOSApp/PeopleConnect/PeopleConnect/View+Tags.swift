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

let PostTagHeight:CGFloat = 15
let PostTagSpace:CGFloat = 15

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

class TagsView: UIView {
    let MaxTags = 32
    var m_tags = Array<UILabel>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        for _ in 0...MaxTags-1 {
            let tag = UILabel(frame: CGRectZero)
            tag.font = statusFont
            tag.layer.cornerRadius = 8
            tag.layer.masksToBounds = true
            tag.hidden = true
            tag.textAlignment = .Center
            tag.textColor = UIColor.whiteColor()
            m_tags.append(tag)
            addSubview(tag)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
