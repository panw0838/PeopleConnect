//
//  Requests.swift
//  PeopleConnect
//
//  Created by apple on 18/11/8.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation
import UIKit
import AFNetworking

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
    let url:String = "https://192.168.0.103:8080/sync"
    let afManager: AFHTTPSessionManager = AFHTTPSessionManager()
    let cerSet: Set<NSData> = AFSecurityPolicy.certificatesInBundle(NSBundle.mainBundle())//NSSet(object: cerData)
    let policy: AFSecurityPolicy = AFSecurityPolicy(pinningMode: AFSSLPinningMode.PublicKey, withPinnedCertificates: cerSet)

    policy.allowInvalidCertificates = true
    policy.validatesDomainName = true

    afManager.securityPolicy = policy
    
    afManager.responseSerializer = AFHTTPResponseSerializer()
    //manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    afManager.GET(url, parameters: nil, progress: nil,
        success: { (task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void in
            let html: NSString = NSString.init(data: responseObject as! NSData, encoding: NSUTF8StringEncoding)!
            print("OK = %s", html)
        },
        failure: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
        })
}
