//
//  Requests.swift
//  PeopleConnect
//
//  Created by apple on 18/11/8.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation
import UIKit

struct IdentityAndTrust {
    var identityRef:SecIdentityRef
    var trust:SecTrustRef
    var certArray:AnyObject
}

func registeRequest(var userInfo : UserInfo) {
    let url: NSURL = NSURL(string: "https://192.168.0.103:8080/register")!
    let request: NSMutableURLRequest = NSMutableURLRequest(URL: url)
    
    request.HTTPMethod = "POST"
    request.timeoutInterval = 20
    
    userInfo.cellNumber = "+8615821112604"
    userInfo.deviceID = (UIDevice.currentDevice().identifierForVendor?.UUIDString)!
}

func httpsGet(urlStr:String) {
}
