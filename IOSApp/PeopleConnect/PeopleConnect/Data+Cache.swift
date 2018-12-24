//
//  Data+Cache.swift
//  PeopleConnect
//
//  Created by apple on 18/12/22.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation

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
