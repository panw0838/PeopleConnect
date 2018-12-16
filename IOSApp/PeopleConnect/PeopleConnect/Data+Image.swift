//
//  Data+Image.swift
//  PeopleConnect
//
//  Created by apple on 18/12/16.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation

let ImgMaxSize = 500000

func compressImage(srcImage:UIImage)->NSData {
    let imgData = UIImagePNGRepresentation(srcImage)
    if imgData?.length < ImgMaxSize {
        return imgData!
    }
    
    let scale = (srcImage.size.width > srcImage.size.height ? srcImage.size.width : srcImage.size.height) / 1024
    let newSize = CGSizeMake(srcImage.size.width/scale, srcImage.size.height/scale)
    UIGraphicsBeginImageContext(newSize);
    srcImage.drawInRect(CGRectMake(0, 0, newSize.width, newSize.height))
    let newImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return UIImagePNGRepresentation(newImg)!
}

