//
//  Conversation.swift
//  PeopleConnect
//
//  Created by apple on 19/1/17.
//  Copyright © 2019年 Pan's studio. All rights reserved.
//

import Foundation
import CoreData


class ConvDB: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    static func fetchRequest()->NSFetchRequest {
        return NSFetchRequest(entityName: "Conversation")
    }
}
