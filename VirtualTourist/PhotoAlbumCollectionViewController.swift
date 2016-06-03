//
//  PhotoAlbumCollectionViewController.swift
//  VirtualTourist
//
//  Created by Atikur Rahman on 6/3/16.
//  Copyright © 2016 Atikur Rahman. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumCollectionViewController: UIViewController {
    
    var annoation: MKAnnotation!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(annoation.coordinate)
    }
}
