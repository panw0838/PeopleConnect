//
//  ConvDB+CoreDataProperties.swift
//  PeopleConnect
//
//  Created by apple on 19/1/17.
//  Copyright © 2019年 Pan's studio. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension ConvDB {

    @NSManaged var id: NSNumber?
    @NSManaged var relationship: NSSet?

}