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
    return cacheDir + "/" + fileName
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
    let path = getContactPhotoPath(cID)
    photo.writeToFile(path, atomically: false)
}