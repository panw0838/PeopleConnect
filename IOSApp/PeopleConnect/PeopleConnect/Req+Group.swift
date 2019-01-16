//
//  Req+Group.swift
//  PeopleConnect
//
//  Created by apple on 19/1/14.
//  Copyright © 2019年 Pan's studio. All rights reserved.
//

import Foundation

func httpSearchGroup(name:String, passed:(()->Void)?, failed:((String?)->Void)?) {
    let params: Dictionary = [
        "user":NSNumber(unsignedLongLong: userInfo.userID),
        "name":name]
    http.postRequest("searchgroup", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            SearchGroupView.results.removeAll()
            if let groupData = processErrorCode(response as! NSData, failed: failed) {
                if let json = getJson(groupData) {
                    if let groupObjs = json["names"] as? [String] {
                        for case let group in groupObjs {
                            SearchGroupView.results.append(group)
                        }
                    }
                }
                passed?()
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            failed?("请求失败")
        })
}

func httpAddGroup(name:String, year:Int, passed:(()->Void)?, failed:((String?)->Void)?) {
    let params: Dictionary = [
        "uid":NSNumber(unsignedLongLong: userInfo.userID),
        "name":name,
        "year":NSNumber(integer: year)]
    http.postRequest("addgroup", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            if let groupData = processErrorCode(response as! NSData, failed: failed) {
                if let json = getJson(groupData) {
                    var newGroup = GroupInfo()
                    newGroup.id = UInt32(json["id"]!.unsignedIntValue)
                    newGroup.name = name
                    addGroup(newGroup)
                    passed?()
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            failed?("请求失败")
    })
}
