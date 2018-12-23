//
//  Data+Country.swift
//  PeopleConnect
//
//  Created by apple on 18/12/15.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation
import CoreTelephony

struct CountryInfo {
    var enName = ""
    var cnName = ""
    var shortName = ""
    var code = 0
    var timeShift:Float = 0
    
    init(line:String) {
        let items = line.componentsSeparatedByString("\t")
        enName = items[0]
        cnName = items[1]
        shortName = items[2]
        code = Int(items[3])!
        timeShift = Float(items[4])!
    }
}

func loadCountryInfo()->Dictionary<Int, CountryInfo> {
    var countryDict = Dictionary<Int, CountryInfo>()
    let mainBundle = NSBundle.mainBundle()
    let filePath = mainBundle.pathForResource("CountryCode", ofType: "")
    let fileData = try? NSString(contentsOfFile: filePath!, encoding: NSUTF8StringEncoding)
    if fileData != nil {
        let lines = fileData!.componentsSeparatedByString("\n")
        var firstLine = true
        for line in lines {
            if firstLine {
                firstLine = false
                continue
            }
            let newCountry = CountryInfo(line: line)
            countryDict[newCountry.code] = newCountry
        }
    }
    return countryDict
}

func getCountryCode()->String {
    let networkInfo = CTTelephonyNetworkInfo()
    let carrier = networkInfo.subscriberCellularProvider
    if carrier != nil {
        return "+" + carrier!.mobileCountryCode!
    }
    return "+86"
}

func checkCNCellNumber(cell:String)->Bool {
    let cellYD = "^1(3[0-9]|4[57]|5[0-35-9]|8[0-9]|7[0678])\\d{8}$"
    let cellLT = "(^1(3[4-9]|4[7]|5[0-27-9]|7[8]|8[2-478])\\d{8}$)|(^1705\\d{7}$)"
    let cellDX = "(^1(3[0-2]|4[5]|5[56]|7[6]|8[56])\\d{8}$)|(^1709\\d{7}$)"
    let preYD = NSPredicate(format: "SELF MATCHES %@", cellYD)
    let preLT = NSPredicate(format: "SELF MATCHES %@", cellLT)
    let preDX = NSPredicate(format: "SELF MATCHES %@", cellDX)
    
    return preYD.evaluateWithObject(cell) || preLT.evaluateWithObject(cell) || preDX.evaluateWithObject(cell)
}