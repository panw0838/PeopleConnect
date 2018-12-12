//
//  View+Settings.swift
//  PeopleConnect
//
//  Created by apple on 18/12/12.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation

let nameFont = UIFont.systemFontOfSize(17.0)
let articleFont = UIFont.systemFontOfSize(15.0)
let commentFont = UIFont.systemFontOfSize(15.0)

// 主色调高亮颜色
let hlTextColor = UIColor(red: 0.28, green: 0.35, blue: 0.54, alpha: 1.0)
let linkTextColor = UIColor(red: 0.09, green: 0.49, blue: 0.99, alpha: 1.0)

let PostItemGap = 5
let PostItemGapF:CGFloat = 5.0

func getTextHeight(text:String, width:CGFloat, font:UIFont)->CGFloat {
    let maxSize = CGSizeMake(width, CGFloat(MAXFLOAT))
    let size = text.boundingRectWithSize(maxSize, options: .UsesLineFragmentOrigin, attributes: ["NSFontAttributeName":font], context: nil)
    return CGFloat(Int(size.height + 1.0))
}
