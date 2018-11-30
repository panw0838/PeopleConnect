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
    var post:UInt64 = 0
    var flag:UInt64 = 0
    var desc:String = ""
    var files:Array<String> = Array<String>()
    var snaps:Array<AnyObject> = Array<AnyObject>()
}

extension PostInfo {
    init?(json: [String: AnyObject]) {
        guard
            let user = json["user"] as? NSNumber,
            let post = json["post"] as? NSNumber,
            let flag = json["flag"] as? NSNumber,
            let desc = json["desc"] as? String,
            let files = json["file"] as? [String]
            //let snaps = json["image"] as? [AnyObject]
            else {
                return nil
        }
        self.user = UInt64(user.unsignedLongLongValue)
        self.post = UInt64(post.unsignedLongLongValue)
        self.flag = UInt64(flag.unsignedLongLongValue)
        self.desc = desc
        self.files = files
        //self.snaps = snaps
    }
}

var postData:PostData = PostData()

class Post {
    var m_info:PostInfo = PostInfo()
    var m_snap:Array<UIImage> = Array<UIImage>()
    var m_imgs:Array<UIImage> = Array<UIImage>()
    var m_imgUrls:Array<String> = Array<String>()
    
    init(info:PostInfo) {
        m_info = info
        
        for file in m_info.files {
            let fileUrl = getFileUrl(info.user, pID: info.post, fileName: file)
            m_imgUrls.append(fileUrl)
        }
    }
}

class PostData {
    var m_posts:Array<Post> = Array<Post>()
    
    func AddPost(info:PostInfo) {
        m_posts.append(Post(info: info))
    }
    
    func numOfPosts()->Int {
        return m_posts.count
    }
    
    func postAtIdx(i:Int)->Post {
        return m_posts[i]
    }
}