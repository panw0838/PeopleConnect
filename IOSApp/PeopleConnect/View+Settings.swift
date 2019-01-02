//
//  View+Settings.swift
//  PeopleConnect
//
//  Created by apple on 18/12/12.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation

let nameFont    = UIFont.systemFontOfSize(15)
let articleFont = UIFont.systemFontOfSize(13)
let commentFont = UIFont.systemFontOfSize(13)
let statusFont  = UIFont.systemFontOfSize(11)
let msgFont     = UIFont.systemFontOfSize(13)


// 主色调高亮颜色
let hlTextColor   = UIColor(red: 0.28, green: 0.35, blue: 0.54, alpha: 1.0)
let linkTextColor = UIColor(red: 0.09, green: 0.49, blue: 0.99, alpha: 1.0)
let selfTextColor = UIColor(red: 0.09, green: 0.49, blue: 0.09, alpha: 1.0)

func getTextHeight(text:String, width:CGFloat, font:UIFont)->CGFloat {
    let maxSize = CGSizeMake(width, CGFloat(MAXFLOAT))
    let style = NSMutableParagraphStyle()
    //style.alignment = .Left
    style.lineBreakMode = .ByWordWrapping
    style.lineSpacing = 2

    let dict = [NSFontAttributeName:font, NSParagraphStyleAttributeName:style]
    let size = text.boundingRectWithSize(maxSize, options: [.UsesLineFragmentOrigin], attributes: dict, context: nil)
    return CGFloat(ceilf(Float(size.height)))
}

func getTextWidth(text:String, height:CGFloat, font:UIFont)->CGFloat {
    let maxSize = CGSizeMake(CGFloat(MAXFLOAT), height)
    let dict = [NSFontAttributeName:font]
    let size = text.boundingRectWithSize(maxSize, options: [.UsesLineFragmentOrigin], attributes: dict, context: nil)
    return CGFloat(ceilf(Float(size.width)))
}

func getMsgSize(text:String, maxSize:CGSize, font:UIFont)->CGSize {
    let dict = [NSFontAttributeName:font]
    let rect = text.boundingRectWithSize(maxSize, options: [.UsesLineFragmentOrigin], attributes: dict, context: nil)
    return rect.size
}

func getAttrTextHeight(text:NSMutableAttributedString, width:CGFloat, font:UIFont)->CGFloat {
    let maxSize = CGSizeMake(width, CGFloat(MAXFLOAT))
    let size = text.boundingRectWithSize(maxSize, options: [.UsesFontLeading, .UsesLineFragmentOrigin], context: nil)
    let baseHeight = Int(size.height + 1)
    let linespace = 10
    let numLines = baseHeight / 14
    //let ttt = ceilf(Float(size.height))
    return CGFloat((numLines-1) * linespace + baseHeight + (numLines == 2 ? 2 : 0))
}

extension UIImage {
    static func resizableImage(name:String)->UIImage {
        let img = UIImage(named: name)
        let insets = UIEdgeInsetsMake((img?.size.height)!/2, (img?.size.width)!/2, (img?.size.height)!/2+1, (img?.size.width)!/2+1)
        return (img?.resizableImageWithCapInsets(insets))!
    }
}