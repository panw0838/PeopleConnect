//
//  Data+Country.swift
//  PeopleConnect
//
//  Created by apple on 18/12/15.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation
import CoreTelephony
import Contacts

var countryDict = Dictionary<Int, CountryInfo>()

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

func loadCountryInfo() {
    if countryDict.count != 0 {
        return
    }
    let mainBundle = NSBundle.mainBundle()
    let filePath = mainBundle.pathForResource("CountryCode", ofType: "")
    
    if let fileData = try? NSString(contentsOfFile: filePath!, encoding: NSUTF8StringEncoding) {
        let lines = fileData.componentsSeparatedByString("\n")
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
}

func getCountryCode()->Int {
    let networkInfo = CTTelephonyNetworkInfo()
    if let carrier = networkInfo.subscriberCellularProvider {
        if carrier.isoCountryCode != nil {
            for info in countryDict.values.enumerate() {
                if info.element.cnName == carrier.isoCountryCode {
                    return info.index
                }
            }
        }
    }
    return 86
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

func checkContactsBookPrivacy()->String {
    var errString = ""
    
    switch (CNContactStore.authorizationStatusForEntityType(.Contacts))
    {
    case .Authorized:
        //存在权限
        //获取通讯录
        break
    case .NotDetermined:
        //权限未知
        //请求权限
        let store = CNContactStore()
        store.requestAccessForEntityType(.Contacts, completionHandler: {(success:Bool, err:NSError?)->Void in
            if success {
            }
            else {
                errString = "请求权限错误"
            }
            })
        break
    case .Restricted:
        //如果没有权限
        errString = "没有权限"
        break
    case .Denied:
        errString = "没有权限"
        break
    }
    
    return errString
}

func getContactsBook()->(names:Array<String>, codes:Array<Int>, cells:Array<String>) {
    let store = CNContactStore()
    let request = CNContactFetchRequest(keysToFetch: [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey])
    var names = Array<String>()
    var codes = Array<Int>()
    var cells = Array<String>()
    do {
        try store.enumerateContactsWithFetchRequest(request,
            usingBlock: {(contact:CNContact, pStop:UnsafeMutablePointer<ObjCBool>)->Void in
                let familyName = (contact.familyName.characters.count > 0 ? " " : "") + contact.familyName
                let name = contact.givenName + familyName
                
                let numbers = contact.phoneNumbers
                for number in numbers {
                    let rawCell:String = (number.value as! CNPhoneNumber).stringValue
                    var cell = ""
                    var code = userInfo.countryCode
                    var processCode = false
                    var formatCell = false
                    
                    for (i, c) in rawCell.characters.enumerate() {
                        if c < "0" || c > "9" {
                            formatCell = true
                        }
                        // +86 process
                        if i == 0 && c == "+" {
                            code = 0
                            processCode = true
                            continue
                        }
                        if processCode && c >= "0" && c <= "9" {
                            code *= 10
                            code += Int(String(c))!
                            continue
                        }
                        if processCode && (c < "0" || c > "9") {
                            processCode = false
                            continue
                        }
                        // 1 (407) process
                        if c == "(" && cell.characters.count > 0 {
                            code = Int(cell)!
                            cell = ""
                            continue
                        }
                        if c >= "0" && c <= "9" {
                            cell.append(c)
                        }
                    }
                    
                    // 86137xxxxxxx process
                    if !formatCell {
                        var index = cell.startIndex.successor()
                        for var i=0; i<3; i++ {
                            let tryCodeStr = cell.substringToIndex(index)
                            if let tryCode = Int(tryCodeStr) {
                                if let info = countryDict[tryCode] {
                                    code = info.code
                                    cell = cell.substringFromIndex(index)
                                    break
                                }
                            }
                            index = index.successor()
                        }
                    }
                    
                    if name.characters.count != 0 && cell.characters.count != 0 {
                        names.append(name)
                        codes.append(code)
                        cells.append(cell)
                        print(name, rawCell, code, cell)
                    }
                }
            }
        )
    }
    catch {
    }
    
    return (names, codes, cells)
}

