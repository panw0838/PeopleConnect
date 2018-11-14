//
//  User.swift
//  PeopleConnect
//
//  Created by apple on 18/11/13.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation

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
    }
}

var userInfo:UserInfo = UserInfo()