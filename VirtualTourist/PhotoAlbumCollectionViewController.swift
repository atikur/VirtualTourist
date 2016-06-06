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
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var infoLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isPhotoAlbumAvailable {
            getSavedPhotos()
        } else {
            downloadPhotos()
        }
        
        infoLabel.hidden = true
        configureMapView()
    }
    
    func configureMapView() {
        let region = MKCoordinateRegion(center: annoation.coordinate, span: MKCoordinateSpanMake(0.02, 0.02))
        mapView.setRegion(region, animated: true)
        
        mapView.addAnnotation(annoation)
    }
    
    func downloadPhotos() {
        FlickrClient.sharedInstance.getPhotosForLocation(annoation.coordinate) {
            photoURLs, errorString in
            
            guard let photoURLs = photoURLs else {
                self.displayError(errorString)
                return
            }
            
            print("Total photos: \(photoURLs.count)")
        }
    }
    
    func displayError(errorString: String?) {
        guard let errorString = errorString else {
            return
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.infoLabel.text = errorString
            self.infoLabel.hidden = false
        }
    }
    
    func getSavedPhotos() {
        print("get previously saved photos")
    }
}
