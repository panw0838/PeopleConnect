//
//  Data+Cache.swift
//  PeopleConnect
//
//  Created by apple on 18/12/22.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation

func getName(cID:UInt64)->String {
    var name = ""
    let data = contactsData.getUser(cID)
    if data != nil {
        name = data!.name
    }
    return name
}

func getPhoto(cID:UInt64)->UIImage {
    var photo = UIImage(named: "default_profile")
    let data = getContactPhoto(cID)
    if data != nil {
        photo = UIImage(data: data!)
    }
    return photo!
}

func getContactPhotoPath(cID:UInt64)->String {
    let cacheDir = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0]
    let fileName = String(cID) + ".png"
    
    return cacheDir + "/photos/" + fileName
}

func getContactPhoto(cID:UInt64)->NSData? {
    let path = getContactPhotoPath(cID)
    let fileMgr = NSFileManager.defaultManager()
    
    if fileMgr.fileExistsAtPath(path) {
        return NSData(contentsOfFile: path)
    }
    else {
        return nil
    }
}

func setContactPhoto(cID:UInt64, photo:NSData) {
    let cacheDir = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0]
    let folder = cacheDir + "/photos"
    let fileMgr = NSFileManager.defaultManager()

    if !fileMgr.fileExistsAtPath(folder) {
        do {
            try fileMgr.createDirectoryAtPath(folder, withIntermediateDirectories: true, attributes: nil)
        } catch {}
    }
    
    let path = getContactPhotoPath(cID)
    photo.writeToFile(path, atomically: true)
}

func getPhotoMissingList(cIDs:Array<UInt64>)->Array<UInt64> {
    var ids = Array<UInt64>()
    for cID in cIDs {
        if getContactPhoto(cID) == nil {
            ids.append(cID)
        }
    }
    return ids
}

func getPreviewKey(info:PostInfo, i:Int)->String {
    return String(info.user) + "_" + String(info.id) + "_" + info.files[i]
}

func getPostPreviewPath(file:String)->String {
    let cacheDir = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0]
    return cacheDir + "/preview/" + file
}

func getPostPreview(file:String)->NSData? {
    let path = getPostPreviewPath(file)
    let fileMgr = NSFileManager.defaultManager()
    
    if fileMgr.fileExistsAtPath(path) {
        return NSData(contentsOfFile: path)
    }
    else {
        return nil
    }
}

func setPostPreview(file:String, data:NSData) {
    let cacheDir = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0]
    let folder = cacheDir + "/preview"
    let fileMgr = NSFileManager.defaultManager()
    
    if !fileMgr.fileExistsAtPath(folder) {
        do {
            try fileMgr.createDirectoryAtPath(folder, withIntermediateDirectories: true, attributes: nil)
        } catch {}
    }
    
    let path = getPostPreviewPath(file)
    data.writeToFile(path, atomically: true)
}

