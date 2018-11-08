//
//  Requests.swift
//  PeopleConnect
//
//  Created by apple on 18/11/8.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation
import UIKit

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

func registeRequest(var userInfo : UserInfo) {
    let url: NSURL = NSURL(string: "https://192.168.0.103:8080/register")!
    let request: NSURLRequest = NSURLRequest(URL: url)
    let response: AutoreleasingUnsafeMutablePointer<NSURLResponse?> = nil
    
    userInfo.cellNumber = "+8615821112604"
    userInfo.deviceID = (UIDevice.currentDevice().identifierForVendor?.UUIDString)!
}