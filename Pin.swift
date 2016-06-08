//
//  Pin.swift
//  VirtualTourist
//
//  Created by Atikur Rahman on 6/7/16.
//  Copyright © 2016 Atikur Rahman. All rights reserved.
//

import Foundation
import CoreData
import MapKit

class Pin: NSManagedObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude!), longitude: CLLocationDegrees(longitude!))
    }
    
    convenience init(coordinate: CLLocationCoordinate2D, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context) {
            self.init(entity: entity, insertIntoManagedObjectContext: context)
            
            self.latitude = coordinate.latitude
            self.longitude = coordinate.longitude
        } else {
            fatalError("Unable to find entity 'Pin'")
        }
    }

}
