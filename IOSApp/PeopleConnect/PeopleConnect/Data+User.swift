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
    var userID : UInt64
    var cellNumber : String
    var mailAddr : String
    var qqNumber : String
    var account : String
    
    var userName : String
    var password : String
    var config : UInt64
    var deviceID : String
    var ipAddress : String
    
    var groups = Array<GroupInfo>()
    
    init () {
        userID = 0
        cellNumber = ""
        mailAddr = ""
        qqNumber = ""
        account = ""
        
        userName = ""
        password = ""
        config = 0
        deviceID = ""
        ipAddress = ""
    }
}

var userInfo:UserInfo = UserInfo()
var userData = User()

class User {
    var m_default = NSUserDefaults.standardUserDefaults()
    
    func saveUserInfo() {
        m_default.setObject(NSNumber(unsignedLongLong: userInfo.userID), forKey: "curUser")
    }
    
    func loadUserInfo() {
        
    }
}