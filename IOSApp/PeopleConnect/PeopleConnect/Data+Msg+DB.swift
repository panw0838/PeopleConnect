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
        //1、创建模型对象
        //获取模型路径
        let modelURL = NSBundle.mainBundle().URLForResource("Model", withExtension: "momd")
        //根据模型文件创建模型对象
        let model = NSManagedObjectModel(contentsOfURL: modelURL!)
        //2、创建持久化存储助理：数据库
        //利用模型对象创建助理对象
        let store = NSPersistentStoreCoordinator(managedObjectModel: model!)
        //数据库的名称和路径
        let docStr = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).last
        let sqlPath = docStr?.stringByAppendingString("/" + String(userInfo.userID) + ".sqlite")
        let sqlUrl = NSURL(fileURLWithPath: sqlPath!)
        
        //设置数据库相关信息 添加一个持久化存储库并设置类型和路径，NSSQLiteStoreType：SQLite作为存储库
        let options = [NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true]
        do {
            try store.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: sqlUrl, options: options)
        }
        catch {
        }
        
        let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.persistentStoreCoordinator = store
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
    func saveMessage(conv:UInt64, info:MsgInfo) {
        let req = MsgDB.fetchRequest()
        req.predicate = NSPredicate(format: "conv == %d AND time == %d AND from = %d and data == %s",
            conv, info.time, info.from, info.data)
        do {
            let result = try context.executeFetchRequest(req) as! [MsgDB]
            if result.count == 0 {
                let msg = NSEntityDescription.insertNewObjectForEntityForName("Message", inManagedObjectContext: context) as! MsgDB
                msg.conv = NSNumber(unsignedLongLong: conv)
                msg.time = NSNumber(unsignedLongLong: info.time)
                msg.type = NSNumber(integer: info.type.rawValue)
                msg.from = NSNumber(unsignedLongLong: info.from)
                msg.data = info.data
                saveContext()
                saveConversation(conv)
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