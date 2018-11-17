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
    var baseURL: String = "https://192.168.0.104:8080/"
    
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
            afManager.POST(url, parameters: params, headers: nil, progress: nil, success: success, failure: fail)
    }
    
    func getIDArrayParam(array:Array<UInt64>)->NSMutableArray {
        let param:NSMutableArray = NSMutableArray()
        for member in array {
            param.addObject(NSNumber(unsignedLongLong: member))
        }
        return param
    }
}
