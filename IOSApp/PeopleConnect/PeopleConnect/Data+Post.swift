//
//  Post.swift
//  PeopleConnect
//
//  Created by apple on 18/11/29.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation
import UIKit
import AFNetworking

struct PostInfo {
    var user:UInt64 = 0
    var time:UInt64 = 0
    var flag:UInt64 = 0
    var content:String = ""
    var files:Array<String> = Array<String>()
    //var snaps:Array<AnyObject> = Array<AnyObject>()
}

extension PostInfo {
    init?(json: [String: AnyObject]) {
        guard
            let user = json["user"] as? NSNumber,
            let time = json["time"] as? NSNumber,
            let flag = json["flag"] as? NSNumber,
            let content = json["cont"] as? String,
            let files = json["file"] as? [String]
            //let snaps = json["image"] as? [AnyObject]
            else {
                return nil
        }
        self.user = UInt64(user.unsignedLongLongValue)
        self.time = UInt64(time.unsignedLongLongValue)
        self.flag = UInt64(flag.unsignedLongLongValue)
        self.content = content
        self.files = files
        //self.snaps = snaps
    }
}

var postData:PostData = PostData()

class Post {
    var m_info:PostInfo = PostInfo()
    var m_imgUrls:Array<String> = Array<String>()
    var m_imgKeys:Array<String> = Array<String>()
    
    init(info:PostInfo) {
        m_info = info
        
        for file in m_info.files {
            let fileUrl = getFileUrl(info.user, pID: info.time, fileName: file)
            m_imgUrls.append(fileUrl)
            m_imgKeys.append(String(m_info.user) + "_" + String(m_info.time) + "_" + file)
        }
    }
}

class PostData {
    var m_posts = Array<Post>()
    var m_snaps = Dictionary<String, UIImage>()
    
    func AddPost(info:PostInfo) {
        m_posts.append(Post(info: info))
    }
    
    func numOfPosts()->Int {
        return m_posts.count
    }
    
    func postAtIdx(i:Int)->Post {
        return m_posts[i]
    }
    
    func getPreviews() {
        var files = Array<String>()
        for post in m_posts {
            for key in post.m_imgKeys {
                files.append(key)
            }
        }
        httpGetSnapshots(files)
    }
}