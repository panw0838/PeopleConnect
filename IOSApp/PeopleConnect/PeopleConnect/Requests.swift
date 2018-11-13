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

struct LoginInfo {
    var cell:String
    var code:String
    var pass:String
}

let http: HttpService = HttpService()

class HttpService {
    var afManager: AFHTTPSessionManager = AFHTTPSessionManager()
    var baseURL: String = "https://192.168.0.103:8080/"
    
    init() {
        let cerSet: Set<NSData> = AFSecurityPolicy.certificatesInBundle(NSBundle.mainBundle())
        let policy: AFSecurityPolicy = AFSecurityPolicy(pinningMode: AFSSLPinningMode.PublicKey, withPinnedCertificates: cerSet)
        
        policy.allowInvalidCertificates = true
        policy.validatesDomainName = true
        
        afManager.securityPolicy = policy
    }
    
    func postRequest(path:String, params:NSDictionary,
        success:(task: NSURLSessionDataTask, responseObject: AnyObject?)->Void,
        fail:(task: NSURLSessionDataTask?, error : NSError)->Void) {
            let url:String = baseURL + path
            afManager.requestSerializer = AFJSONRequestSerializer()
            afManager.responseSerializer = AFHTTPResponseSerializer()
            afManager.POST(url, parameters: params, progress: nil, success: success, failure: fail)
    }
    
    func registryRequest() {
        let registryURL: String = baseURL + "registry"
        let cellNumber:String = "8615821112604"
        let password: String = "123456"
        let deviceID:String = (UIDevice.currentDevice().identifierForVendor?.UUIDString)!
        let params: Dictionary = ["cell":cellNumber, "code":"0838", "pass":password, "device":deviceID]

        afManager.requestSerializer = AFJSONRequestSerializer()
        afManager.responseSerializer = AFHTTPResponseSerializer()
        
        afManager.POST(registryURL,
            parameters: params,
            progress: nil,
            success: { (task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void in
                let html: String = String.init(data: responseObject as! NSData, encoding: NSUTF8StringEncoding)!
                if (html.hasPrefix("Success")) {
                    print("%s", html)
                }
                else {
                    print("%s", html)
                }
                //let jsonObj = try? NSJSONSerialization.JSONObjectWithData(responseObject as! NSData, options: .MutableContainers)
                //if (jsonObj != nil) {
                //    let dict: NSDictionary = jsonObj as! NSDictionary
                //    print("%s, %s, %s", dict["cell"], dict["code"], dict["pass"])
                //}
            },
            failure: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
                print("请求失败")
            })
    }
    
    func loginRequest() {
        let loginURL: String = baseURL + "login"
        let params: Dictionary = ["cell":"8615821112604", "code":"0838", "pass":"123456"]

        afManager.requestSerializer = AFJSONRequestSerializer()
        afManager.responseSerializer = AFHTTPResponseSerializer()
        
        afManager.POST(loginURL,
            parameters: params,
            progress: nil,
            success: { (task: NSURLSessionDataTask, responseObject: AnyObject?) -> Void in
                let html: String = String.init(data: responseObject as! NSData, encoding: NSUTF8StringEncoding)!
                if (html.hasPrefix("Success")) {
                    print("%s", html)
                }
                else {
                    print("%s", html)
                }
            },
            failure: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
                print("请求失败")
            })
    }
}
