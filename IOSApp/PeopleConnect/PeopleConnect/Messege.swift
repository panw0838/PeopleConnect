//
//  Messege.swift
//  PeopleConnect
//
//  Created by apple on 18/11/18.
//  Copyright © 2018年 Pan's studio. All rights reserved.
//

import Foundation

struct MessegeInfo {
    var from:UInt64 = 0
    var time:String = ""
    var data:String = ""
    
}

extension MessegeInfo {
    init?(json: [String: AnyObject]) {
        guard
            let from = json["from"] as? NSNumber,
            let time = json["time"] as? String,
            let data = json["cont"] as? String
            else {
                return nil
        }
        self.from = UInt64(from.unsignedLongLongValue)
        self.time = time
        self.data = data
    }
}

class Messege {
    var m_from:UInt64 = 0
    var m_messeges:Array<MessegeInfo> = Array<MessegeInfo>()
    
    init(from:UInt64) {
        m_from = from
    }
    
    func addMessege(newMessege:MessegeInfo) {
        m_messeges.append(newMessege)
    }
}

class MessegeData {
    var m_data:Array<Messege> = Array<Messege>()
    
    func GetMessege(from:UInt64)->Messege {
        for data in m_data {
            if data.m_from == from {
                return data
            }
        }
        let data = Messege(from: from)
        m_data.append(data)
        return data
    }
    
    func PopMessege(from:UInt64)->Messege? {
        for (i, data) in m_data.enumerate() {
            if data.m_from == from {
                m_data.removeAtIndex(i)
                return data
            }
        }
        return nil
    }
    
    func AddNewMesseges(newMesseges:Array<MessegeInfo>) {
        for newMessege in newMesseges {
            var data = PopMessege(newMessege.from)
            if data == nil {
                data = Messege(from: newMessege.from)
            }
            data!.addMessege(newMessege)
            m_data.append(data!)
        }
    }
}

var messegeData:MessegeData = MessegeData()
