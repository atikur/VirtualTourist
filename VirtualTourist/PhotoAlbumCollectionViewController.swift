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
    var isPhotoAlbumAvailable = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isPhotoAlbumAvailable {
            getSavedPhotos()
        } else {
            downloadPhotos()
        }
    }
    
    func downloadPhotos() {
        FlickrClient.sharedInstance.getPhotosForLocation(annoation.coordinate) {
            photoURLs, errorString in
            
            guard let photoURLs = photoURLs else {
                print("Error: \(errorString)")
                return
            }
            
            print("Total photos: \(photoURLs.count)")
        }
    }
    
    func getSavedPhotos() {
        print("get previously saved photos")
    }
}
