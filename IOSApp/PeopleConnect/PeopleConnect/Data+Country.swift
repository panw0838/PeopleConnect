//
//  Data+Country.swift
//  PeopleConnect
//
//  Created by apple on 18/12/15.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation

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