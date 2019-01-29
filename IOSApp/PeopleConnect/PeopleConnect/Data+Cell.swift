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

func getCountryCode(dict:Dictionary<Int, CountryInfo>)->Int {
    let networkInfo = CTTelephonyNetworkInfo()
    if let carrier = networkInfo.subscriberCellularProvider {
        if carrier.isoCountryCode != nil {
            for info in dict.values.enumerate() {
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

func getContactsBook()->(names:Array<String>, cells:Array<String>) {
    let store = CNContactStore()
    let request = CNContactFetchRequest(keysToFetch: [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey])
    var names = Array<String>()
    var cells = Array<String>()
    do {
        try store.enumerateContactsWithFetchRequest(request,
            usingBlock: {(contact:CNContact, pStop:UnsafeMutablePointer<ObjCBool>)->Void in
                let familyName = (contact.familyName.characters.count > 0 ? " " : "") + contact.familyName
                let name = contact.givenName + familyName
                var cell = ""
                
                let numbers = contact.phoneNumbers
                for number in numbers {
                    if number.label == CNLabelPhoneNumberMobile || (cell.characters.count == 0 && number.label == CNLabelPhoneNumberMain) {
                        let numString:String = (number.value as! CNPhoneNumber).stringValue
                        var finalString:String = ""
                        for c in numString.characters {
                            if c != " " && c != "(" && c != ")" && c != "-" {
                                finalString.append(c)
                            }
                        }
                        cell = finalString
                    }
                }
                
                if name.characters.count != 0 && cell.characters.count != 0 {
                    names.append(name)
                    cells.append(cell)
                    print(name, cell)
                }
        })
    }
    catch {
    }
    
    return (names, cells)
}

