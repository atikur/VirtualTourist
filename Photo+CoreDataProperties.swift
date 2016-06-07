//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Atikur Rahman on 6/7/16.
//  Copyright © 2016 Atikur Rahman. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Photo {

    @NSManaged var imageData: NSData?
    @NSManaged var pin: Pin?

}
