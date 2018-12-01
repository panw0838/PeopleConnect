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
    //var snaps:Array<AnyObject> = Array<AnyObject>()
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
    var m_imgUrls:Array<String> = Array<String>()
    var m_imgKeys:Array<String> = Array<String>()
    
    init(info:PostInfo) {
        m_info = info
        
        for file in m_info.files {
            let fileUrl = getFileUrl(info.user, pID: info.post, fileName: file)
            m_imgUrls.append(fileUrl)
            m_imgKeys.append(String(m_info.user) + "_" + String(m_info.post) + "_" + file)
        }
        
/*        for snap in m_info.snaps {
            let dict = snap as! NSDictionary
            let rect = (dict["Rect"] as! NSDictionary)["Max"] as! NSDictionary
            let width = (rect["X"] as! NSNumber).integerValue
            let height = (rect["Y"] as! NSNumber).integerValue
            let stride = (dict["Stride"] as! NSNumber).integerValue
            let data = (dict["Pix"] as! NSMutableString)
            let bytesPerPixel = stride / width
            let bytes = malloc(stride * height)
            memcpy(bytes, (data.dataUsingEncoding(NSASCIIStringEncoding)?.bytes)!, stride*height)
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGBitmapInfo.ByteOrderDefault//CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue)
            let provider = CGDataProviderCreateWithData(nil, bytes, stride*height, nil)
            
            let cgImgRef = CGImageCreate(width, height, bytesPerPixel/4*8, bytesPerPixel*8, stride, colorSpace, bitmapInfo, provider, nil, false, .RenderingIntentDefault)
            //let context = CGBitmapContextCreate(bytes, width, height, bytesPerPixel/4*8, stride, colorSpace, bitmapInfo.rawValue)

            //CGContextDrawImage(context, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), cgImgRef)
            //let cgImg = CGBitmapContextCreateImage(context)
            
            let image = UIImage(CGImage: cgImgRef!, scale: 1.0, orientation: UIImageOrientation.DownMirrored)
            
            m_snap.append(image)
        }*/
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