//
//  Data+msg+DB.swift
//  PeopleConnect
//
//  Created by apple on 19/1/17.
//  Copyright © 2019年 Pan's studio. All rights reserved.
//

import Foundation
import CoreData

class CoreDataManager: NSObject {
    
    // 单例
    static let shared = CoreDataManager()
    
    // 拿到AppDelegate中创建好了的NSManagedObjectContext
    lazy var context: NSManagedObjectContext = {
        let context = (UIApplication.sharedApplication().delegate as! AppDelegate).context
        return context
    }()
    
    // 更新数据
    private func saveContext() {
        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
    
    func saveConversation(id:UInt64) {
        let req = ConvDB.fetchRequest()
        req.predicate = NSPredicate(format: "id == %d", id)
        do {
            let result = try context.executeFetchRequest(req) as! [MsgDB]
            if result.count == 0 {
                let conv = NSEntityDescription.insertNewObjectForEntityForName("Conversation", inManagedObjectContext: context) as! ConvDB
                conv.id = NSNumber(unsignedLongLong: id)
                saveContext()

            }
        } catch {
            fatalError();
        }
    }
    
    // 增加数据
    func saveMessage(info:MsgInfo) {
        let req = MsgDB.fetchRequest()
        req.predicate = NSPredicate(format: "conv == %d AND time == %d AND from = %d and data == %s",
            info.getConversationID(), info.time, info.from, info.data)
        do {
            let result = try context.executeFetchRequest(req) as! [MsgDB]
            if result.count == 0 {
                let msg = NSEntityDescription.insertNewObjectForEntityForName("Message", inManagedObjectContext: context) as! MsgDB
                msg.conv = NSNumber(unsignedLongLong: info.getConversationID())
                msg.time = NSNumber(unsignedLongLong: info.time)
                msg.type = NSNumber(integer: info.type.rawValue)
                msg.from = NSNumber(unsignedLongLong: info.from)
                msg.data = info.data
                saveContext()
                saveConversation(info.getConversationID())
            }
        } catch {
            fatalError();
        }
    }
    
    // 获取数据
    func getMessages(conv: UInt64) -> [MsgDB] {
        let req = MsgDB.fetchRequest()
        req.predicate = NSPredicate(format: "conv == %d", conv)
        do {
            let result = try context.executeFetchRequest(req) as! [MsgDB]
            return result
        } catch {
            fatalError();
        }
    }
    
    // 获取所有数据
    func getAllConvs() -> [ConvDB] {
        let req = ConvDB.fetchRequest()
        do {
            let result = try context.executeFetchRequest(req) as! [ConvDB]
            return result
        } catch {
            fatalError();
        }
    }
    
    // 修改数据
    /*
    func changeMsgTime(conv: UInt64, newName: String, newAge: Int16) {
        let req = MsgDB.fetchRequest()
        req.predicate = NSPredicate(format: "conv == %d time == 0", conv)
        do {
            let result = try context.fetch(fetchRequest)
            for person in result {
                person.name = newName
                person.age = newAge
            }
        } catch {
            fatalError();
        }
        saveContext()
    }
*/
    
    // 删除数据
    func deleteMsgs(conv: UInt64) {
        let result = getMessages(conv)
        for msg in result {
            context.delete(msg)
        }
    }
    
    // 删除所有数据
    func deleteConv(id:UInt64) {
        let result = getAllConvs()
        for conv in result {
            if conv.id!.unsignedLongLongValue == id {
                context.delete(conv)
            }
        }
        deleteMsgs(id)
        saveContext()
    }
}