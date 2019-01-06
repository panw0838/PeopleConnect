//
//  Data+Utility.swift
//  PeopleConnect
//
//  Created by apple on 18/12/30.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation

let StartTime = NSDate(timeIntervalSinceReferenceDate: 0)

func getTimeString(time:UInt64)->String {
    if time == 0 {
        return "发送失败"
    }
    let tid = NSDate(timeInterval: Double(time), sinceDate: StartTime)
    let now = NSDate(timeIntervalSinceNow: 0)
    let diff = now.timeIntervalSinceDate(tid)
    
    let minites = diff / 60
    let hours   = minites / 60
    let days    = hours / 24
    let months  = days / 30
    let years   = days / 365
    
    if Int(years) > 0 {
        return String(Int(years)) + "年前"
    }
    if Int(months) > 0 {
        return String(Int(months)) + "月前"
    }
    if Int(days) > 0 {
        return String(Int(days)) + "天前"
    }
    if Int(hours) > 0 {
        return String(Int(hours)) + "小时前"
    }
    if Int(minites) > 0 {
        return String(Int(minites)) + "分钟前"
    }
    return "刚刚"
}

func getFormatTime(time:UInt64)->String {
    let date = NSDate(timeInterval: Double(time), sinceDate: StartTime)
    let format = NSDateFormatter()
    
    format.setLocalizedDateFormatFromTemplate("yyyy-MM-dd HH:mm:ss")
    
    return format.stringFromDate(date)
}