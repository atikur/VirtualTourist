//
//  Photo.swift
//  VirtualTourist
//
//  Created by Atikur Rahman on 6/7/16.
//  Copyright © 2016 Atikur Rahman. All rights reserved.
//

import Foundation
import CoreData


class Photo: NSManagedObject {

    convenience init(imageUrlString: String?, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context) {
            self.init(entity: entity, insertIntoManagedObjectContext: context)
            self.imageUrlString = imageUrlString
            self.imageData = nil
        } else {
            fatalError("Unable to find entity 'Photo'")
        }
    }

}
