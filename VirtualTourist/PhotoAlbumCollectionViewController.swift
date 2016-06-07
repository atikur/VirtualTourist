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
    
    // MARK: - Properties
    
    let maxPhotos = 21
    
    let minLineSpacing: CGFloat = 3.0
    let minInterItemSpacing: CGFloat = 3.0
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var photoURLs = [NSURL]()
    
    var annoation: MKAnnotation!
    var isPhotoAlbumAvailable = false
    
    // MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isPhotoAlbumAvailable {
            getSavedPhotos()
        } else {
            downloadPhotos()
        }
        
        collectionView.dataSource = self
        infoLabel.hidden = true
        configureMapView()
        configureFlowLayout(view.frame.size.width)
    }
    
    func showActivityIndicator(show: Bool) {
        activityIndicator.hidden = !show
        
        if show {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
        }
    }
    
    func configureFlowLayout(width: CGFloat) {
        let dimension = (width - (2 * minLineSpacing)) / 3.0
        
        flowLayout.minimumLineSpacing = minLineSpacing
        flowLayout.minimumInteritemSpacing = minInterItemSpacing
        flowLayout.itemSize = CGSizeMake(dimension, dimension)
    }
    
    func configureMapView() {
        let region = MKCoordinateRegion(center: annoation.coordinate, span: MKCoordinateSpanMake(0.02, 0.02))
        mapView.setRegion(region, animated: true)
        
        mapView.addAnnotation(annoation)
    }
    
    func downloadPhotos() {
        showActivityIndicator(true)
        
        FlickrClient.sharedInstance.getPhotosForLocation(annoation.coordinate) {
            photoURLs, errorString in
            
            guard let photoURLs = photoURLs else {
                self.displayError(errorString)
                return
            }
            
            self.displayPlaceholders(photoURLs)
        }
    }
    
    func displayPlaceholders(photoURLs: [NSURL]) {
        print("Total photos: \(photoURLs.count)")
        
        let photosCount = photoURLs.count > maxPhotos ? maxPhotos : photoURLs.count
        
        self.photoURLs = Array(photoURLs.prefix(photosCount))
        
        dispatch_async(dispatch_get_main_queue()) {
            self.showActivityIndicator(false)
            self.collectionView.reloadData()
        }
    }
    
    func displayError(errorString: String?) {
        guard let errorString = errorString else {
            return
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.showActivityIndicator(false)
            self.infoLabel.text = errorString
            self.infoLabel.hidden = false
        }
    }
    
    func getSavedPhotos() {
        print("get previously saved photos")
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        if toInterfaceOrientation.isLandscape {
            configureFlowLayout(max(view.frame.size.width, view.frame.size.height))
        } else {
            configureFlowLayout(min(view.frame.size.width, view.frame.size.height))
        }
    }
}

extension PhotoAlbumCollectionViewController: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoURLs.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        cell.imageView.image = UIImage(named: "placeholder")
        cell.activityIndicator.startAnimating()
        
        let url = photoURLs[indexPath.row]
        let request = NSURLRequest(URL: url)
        let task = FlickrClient.sharedInstance.session.dataTaskWithRequest(request) {
            data, response, error in
            
            guard let data = data else {
                return
            }
            
            guard let image = UIImage(data: data) else {
                return
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                cell.activityIndicator.stopAnimating()
                cell.activityIndicator.hidden = true
                cell.imageView.image = image
            }
        }
        task.resume()
        
        return cell
    }
}
