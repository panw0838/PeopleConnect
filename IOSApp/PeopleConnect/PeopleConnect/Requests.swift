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

protocol SearchContactCallback {
    func SearchUpdateUI(uid:UInt64)->Void
}

let httpErrMsg:Dictionary<UInt8, String> = [
    1:"服务器错误",
    2:"国家码错误",
    3:"手机号错误",
    4:"密码错误",
    5:"头像错误"]

let http: HttpService = HttpService()

var searchCallbacks:Array<SearchContactCallback> = Array<SearchContactCallback>()

func processErrorCode(data:NSData, failed:((String?)->Void)?)->NSData? {
    var errCode:UInt8 = 0
    data.getBytes(&errCode, length: sizeof(UInt8))
    if errCode == 0 {
        return data.subdataWithRange(NSRange(location: 1, length: data.length-1))
    }
    else {
        failed?(httpErrMsg[errCode])
        return nil
    }
}

func getErrorCode(data:NSData)->UInt8 {
    var errCode:UInt8 = 0
    data.getBytes(&errCode, length: sizeof(UInt8))
    return errCode
}

func splitData(srcData:NSData)->Array<NSData> {
    var lens = Array<UInt32>()
    var datas = Array<NSData>()
    var numDatas:UInt8 = 0
    var offset = 1
    
    srcData.getBytes(&numDatas, length: sizeof(UInt8))
    
    for var i:UInt8=0; i<numDatas; i++ {
        var len:UInt32 = 0
        let subData = srcData.subdataWithRange(NSRange(location: offset, length: sizeof(UInt32)))
        subData.getBytes(&len, length: sizeof(UInt32))
        lens.append(len)
        offset += sizeof(UInt32)
    }
    
    for var i:UInt8=0; i<numDatas; i++ {
        let subData = srcData.subdataWithRange(NSRange(location: offset, length: Int(lens[Int(i)])))
        offset += Int(lens[Int(i)])
        datas.append(subData)
    }
    
    return datas
}

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
    
    func getFile(fileName:String,
                 success:(task: NSURLSessionDataTask, responseObject: AnyObject?)->Void,
                 fail:(task: NSURLSessionDataTask?, error : NSError)->Void) {
        let url:String = baseURL + "files/" + fileName
        afManager.requestSerializer = AFHTTPRequestSerializer()
        afManager.responseSerializer = AFHTTPResponseSerializer()
        afManager.GET(url, parameters: nil, headers: nil, progress: nil, success: success, failure: fail)
    }
    
    func postRequest(path:String, params:NSDictionary,
        success:(task: NSURLSessionDataTask, responseObject: AnyObject?)->Void,
        fail:(task: NSURLSessionDataTask?, error : NSError)->Void) {
            
        let url:String = baseURL + path
        afManager.requestSerializer = AFJSONRequestSerializer()
        afManager.responseSerializer = AFHTTPResponseSerializer()
        afManager.POST(url, parameters: params, headers: nil, progress: nil, success: success, failure: fail)
    }
    
    func postDataRequest(path:String, params:NSDictionary,
            constructingBodyWithBlock block:((AFMultipartFormData) -> Void)?,
            progress uploadProgress: ((NSProgress) -> Void)?,
            success:(task: NSURLSessionDataTask, responseObject: AnyObject?)->Void,
            fail:(task: NSURLSessionDataTask?, error : NSError)->Void) {
        let url:String = baseURL + path
        afManager.requestSerializer = AFJSONRequestSerializer()
        afManager.responseSerializer = AFHTTPResponseSerializer()
        afManager.requestSerializer.timeoutInterval = 20
        afManager.responseSerializer.acceptableContentTypes = Set<String>([
            "text/plain",
            "multipart/form-data",
            "application/json",
            "text/html",
            "image/jpeg",
            "image/png",
            "application/octet-stream",
            "text/json"])
        afManager.POST(url, parameters: params, headers: nil, constructingBodyWithBlock: block, progress: nil, success: success, failure: fail)
    }
    
    func getUInt32ArrayParam(array:Array<UInt32>)->NSMutableArray {
        let param:NSMutableArray = NSMutableArray()
        for member in array {
            param.addObject(NSNumber(unsignedInt: member))
        }
        return param
    }
    
    func getUInt64ArrayParam(array:Array<UInt64>)->NSMutableArray {
        let param:NSMutableArray = NSMutableArray()
        for member in array {
            param.addObject(NSNumber(unsignedLongLong: member))
        }
        return param
    }
    
    func getStringArrayParam(array:Array<String>)->NSMutableArray {
        let param:NSMutableArray = NSMutableArray()
        for member in array {
            param.addObject(member)
        }
        return param
    }
}
