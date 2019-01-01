//
//  Requests+Post.swift
//  PeopleConnect
//
//  Created by apple on 18/11/26.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation
import AFNetworking

func getFileUrl(cID:UInt64, pID:UInt64, fileName:String)->String {
    return String(cID) + "/" + String(pID) + "/" + fileName
}

func httpGetPostsUsers(cIDs:Array<UInt64>, post:PostData) {
    let params:Dictionary = [
        "user":NSNumber(unsignedLongLong: userInfo.userID),
        "cids":http.getUInt64ArrayParam(cIDs)]
    http.postRequest("users", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let conData = processErrorCode(response as! NSData, failed: nil)
            if conData != nil {
                if let json = try? NSJSONSerialization.JSONObjectWithData(conData!, options: .MutableContainers) as! [String:AnyObject] {
                    if let contactObjs = json["users"] as? [AnyObject] {
                        for case let contactObj in (contactObjs as? [[String:AnyObject]])! {
                            if let contact = ContactInfo(json: contactObj) {
                                contactsData.m_contacts[contact.user] = contact
                            }
                        }
                        post.UpdateDelegate()
                    }
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
        }
    )
}

func httpGetPostsPhotos(cIDs:Array<UInt64>, post:PostData) {
    let params:Dictionary = [
        "user":NSNumber(unsignedLongLong: userInfo.userID),
        "cids":http.getUInt64ArrayParam(cIDs)]
    http.postRequest("photos", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let photosData = processErrorCode(response as! NSData, failed: nil)
            if photosData != nil {
                let subDatas = splitData(photosData!)
                for (i, cID) in cIDs.enumerate() {
                    contactsData.setPhoto(cID, data: subDatas[i], update: true)
                }
                post.UpdateDelegate()
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
        }
    )
}

func addPost(data:PostData, postObjs:[AnyObject]) {
    for case let postObj in (postObjs as? [[String:AnyObject]])! {
        if let post = PostInfo(json: postObj) {
            data.AddPost(post)
            // add comments
            if let cmtObjs = postObj["cmt"] as? [AnyObject] {
                addComment(data.m_posts.last!, cmtObjs: cmtObjs)
            }
        }
    }
}

func httpSendPost(flag:UInt64, desc:String, datas:Array<NSData>, groups:Array<UInt32>, nearby:Bool) {
    let params: Dictionary = [
        "user":NSNumber(unsignedLongLong: userInfo.userID),
        "flag":NSNumber(unsignedLongLong: flag),
        "cont":desc,
        "X":NSNumber(double: userInfo.x),
        "Y":NSNumber(double: userInfo.y),
        "group":http.getUInt32ArrayParam(groups),
        "near":NSNumber(bool: nearby)]
    http.postDataRequest("newpost", params: params,
        constructingBodyWithBlock: { (formData: AFMultipartFormData) -> Void in
            for (idx, data) in datas.enumerate() {
                formData.appendPartWithFileData(data, name:String(idx), fileName:String(idx), mimeType: "image/jpeg")
            }
        },
        progress: nil,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let retData = processErrorCode(response as! NSData, failed: nil)
            if retData != nil {
                if let json = try? NSJSONSerialization.JSONObjectWithData(retData!, options: .MutableContainers) {
                    let dict: NSDictionary = json as! NSDictionary
                    let pID = (UInt64)((dict["post"]?.unsignedLongLongValue)!)
                    var postInfo = PostInfo()
                    postInfo.user = userInfo.userID
                    postInfo.id = pID
                    postInfo.flag = flag
                    postInfo.content = desc
                    for (idx, data) in datas.enumerate() {
                        postInfo.files.append(String(idx)+".png")
                        let previewKey = getPreviewKey(postInfo, i: idx)
                        previews[previewKey] = UIImage(data: data)
                    }
                    selfPosts.AddPost(postInfo)
                    selfPosts.UpdateDelegate()
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
        }
    )
}

func httpDeletePost(post:Post) {
    let params: Dictionary = [
        "uid":NSNumber(unsignedLongLong: userInfo.userID),
        "pid":NSNumber(unsignedLongLong: post.m_info.id)]
    http.postRequest("delpost", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let errCode = getErrorCode(response as! NSData)
            if errCode == 0 {
                for (idx, p) in (post.m_father?.m_posts.enumerate())! {
                    if p.m_info.id == post.m_info.id && p.m_info.user == post.m_info.user {
                        post.m_father?.m_posts.removeAtIndex(idx)
                        post.m_father?.UpdateDelegate()
                        break
                    }
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
        }
    )
}

func httpSyncFriendsPost(pIDs:Array<UInt64>, oIDs:Array<UInt64>, cIDs:Array<UInt64>) {
    let lastPost = (friendPosts.m_posts.count == 0 ? 0 : friendPosts.m_posts.last?.m_info.id)
    let params: Dictionary = [
        "user":NSNumber(unsignedLongLong: userInfo.userID),
        "last":NSNumber(unsignedLongLong: lastPost!),
        "pids":http.getUInt64ArrayParam(pIDs),
        "oids":http.getUInt64ArrayParam(oIDs),
        "cids":http.getUInt64ArrayParam(cIDs)]
    http.postRequest("syncposts", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let postsData = processErrorCode(response as! NSData, failed: nil)
            if postsData != nil {
                if let json = getJson(postsData!) {
                    if let postObjs = json["posts"] as? [AnyObject] {
                        addPost(friendPosts, postObjs: postObjs)
                        friendPosts.getPreviews()
                        friendPosts.UpdateDelegate()
                    }
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
        }
    )
}

func httpSyncContactPost(cID:UInt64, pIDs:Array<UInt64>, oIDs:Array<UInt64>, cIDs:Array<UInt64>) {
    var postData:PostData?
    
    if cID == userInfo.userID {
        postData = selfPosts
    }
    else {
        postData = contactsPosts[cID]
    }
    
    let params: Dictionary = [
        "uid":NSNumber(unsignedLongLong: userInfo.userID),
        "cid":NSNumber(unsignedLongLong: cID),
        "pids":http.getUInt64ArrayParam(pIDs),
        "oids":http.getUInt64ArrayParam(oIDs),
        "cids":http.getUInt64ArrayParam(cIDs)]
    
    postData!.clear()

    http.postRequest("synccontactposts", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let postsData = processErrorCode(response as! NSData, failed: nil)
            if postsData != nil {
                if let json = getJson(postsData!) {
                    if let postObjs = json["posts"] as? [AnyObject] {
                        addPost(postData!, postObjs: postObjs)
                        postData!.getPreviews()
                        postData!.UpdateDelegate()
                    }
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
        }
    )
}

func httpSyncNearbyPost() {
    let params: Dictionary = [
        "uid":NSNumber(unsignedLongLong: userInfo.userID),
        "x":NSNumber(double: userInfo.x),
        "y":NSNumber(double: userInfo.y)]
    http.postRequest("syncnearbyposts", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let postsData = processErrorCode(response as! NSData, failed: nil)
            if postsData != nil {
                if let json = getJson(postsData!) {
                    if let postObjs = json["posts"] as? [AnyObject] {
                        addPost(nearPosts, postObjs: postObjs)
                        nearPosts.getContacts()
                        nearPosts.getPreviews()
                        nearPosts.UpdateDelegate()
                    }
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
        }
    )
}

func httpSyncGroupPost(gID:UInt32, pIDs:Array<UInt64>, oIDs:Array<UInt64>, cIDs:Array<UInt64>) {
    let params: Dictionary = [
        "uid":NSNumber(unsignedLongLong: userInfo.userID),
        "gid":NSNumber(unsignedInt: gID),
        "pids":http.getUInt64ArrayParam(pIDs),
        "oids":http.getUInt64ArrayParam(oIDs),
        "cids":http.getUInt64ArrayParam(cIDs)]

    http.postRequest("syncgroupposts", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let postsData = processErrorCode(response as! NSData, failed: nil)
            if postsData != nil {
                if let json = getJson(postsData!) {
                    if let postObjs = json["posts"] as? [AnyObject] {
                        addPost(groupsPosts[gID]!, postObjs: postObjs)
                        groupsPosts[gID]!.getContacts()
                        groupsPosts[gID]!.getPreviews()
                        groupsPosts[gID]!.UpdateDelegate()
                    }
                }
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
        }
    )
}


func httpGetSnapshots(files:Array<String>, post:PostData) {
    let fileParam = http.getStringArrayParam(files)
    let params: Dictionary = ["files":fileParam]
    http.postRequest("previews", params: params,
        success: { (task: NSURLSessionDataTask, response: AnyObject?) -> Void in
            let previewsData = processErrorCode(response as! NSData, failed: nil)
            if previewsData != nil {
                let subDatas = splitData(previewsData!)
                for (i, file) in files.enumerate() {
                    setPostPreview(file, data: subDatas[i])
                    previews[file] = UIImage(data: subDatas[i])
                }
                post.UpdateDelegate()
            }
        },
        fail: { (task: NSURLSessionDataTask?, error : NSError) -> Void in
            print("请求失败")
        }
    )
}
