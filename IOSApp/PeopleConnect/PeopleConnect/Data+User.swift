//
//  User.swift
//  PeopleConnect
//
//  Created by apple on 18/11/13.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation

struct GroupInfo {
    var id:UInt32 = 0
    var name:String = ""
}

struct UserInfo {
    var userID : UInt64 = 0
    var countryCode: Int = 0
    var cellNumber : String = ""
    var mailAddr : String = ""
    var qqNumber : String = ""
    var account : String = ""
    
    var userName : String = ""
    var password : String = ""
    var config : UInt64 = 0
    var deviceID : String = ""
    var ipAddress : String = ""
    
    var groups = Array<GroupInfo>()
}

var userInfo:UserInfo = UserInfo()
var userData = User()

class User {
    func setCurUser() {
        let user = NSUserDefaults()
        user.setObject(NSNumber(unsignedLongLong: userInfo.userID), forKey: "user")
        user.setObject(NSNumber(integer: userInfo.countryCode), forKey: "code")
        user.setObject(userInfo.cellNumber, forKey: "cell")
        user.setObject(userInfo.password, forKey: "pass")
    }
    
    func getCurUser()->Bool {
        let user = NSUserDefaults()
        let uIDObj = user.objectForKey("user")
        let codeObj = user.objectForKey("code")
        let cellObj = user.objectForKey("cell")
        let passObj = user.objectForKey("pass")
        if uIDObj != nil && codeObj != nil && cellObj != nil && passObj != nil {
            userInfo.userID = (uIDObj as! NSNumber).unsignedLongLongValue
            userInfo.countryCode = (codeObj as! NSNumber).integerValue
            userInfo.cellNumber = cellObj as! String
            userInfo.password = passObj as! String
            return true
        }
        else {
            return false
        }
    }
}