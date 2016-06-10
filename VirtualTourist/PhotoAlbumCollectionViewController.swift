//
//  PhotoAlbumCollectionViewController.swift
//  VirtualTourist
//
//  Created by Atikur Rahman on 6/3/16.
//  Copyright © 2016 Atikur Rahman. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumCollectionViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    let maxPhotos = 21
    
    let minLineSpacing: CGFloat = 3.0
    let minInterItemSpacing: CGFloat = 3.0
    
    let stack = (UIApplication.sharedApplication().delegate as! AppDelegate).stack
    
    var pin: Pin!
    
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    var fetchedResultsController: NSFetchedResultsController!
    
    // MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        infoLabel.hidden = true
        
        configureMapView()
        configureFlowLayout(view.frame.size.width)
        
        let storedPhotos = fetchAllPhotos()
        
        if storedPhotos.isEmpty {
            downloadPhotos()
        } else {
            showActivityIndicator(false)
            print("found: \(storedPhotos.count)")
        }
    }
    
    func fetchAllPhotos() -> [Photo] {
        var photos = [Photo]()
        
        // create fetch request
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        
        // create predicate
        let predicate = NSPredicate(format: "pin = %@", pin)
        fetchRequest.predicate = predicate
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.context , sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            if let results = fetchedResultsController.fetchedObjects as? [Photo] {
                photos = results
            }
        } catch {
            print("Error while trying to fetch photos.")
        }
        
        return photos
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
        let region = MKCoordinateRegion(center: pin.coordinate, span: MKCoordinateSpanMake(0.02, 0.02))
        mapView.setRegion(region, animated: true)
        
        mapView.addAnnotation(pin)
    }
    
    func downloadPhotos() {
        showActivityIndicator(true)
        
        FlickrClient.sharedInstance.getPhotosForLocation(pin.coordinate) {
            photoURLs, errorString in
            
            guard let photoURLs = photoURLs else {
                self.displayError(errorString)
                return
            }
            
            self.displayPlaceholders(photoURLs)
        }
    }
    
    func displayPlaceholders(photoURLs: [String]) {
        print("Total photos: \(photoURLs.count)")
        
        let photosCount = photoURLs.count > maxPhotos ? maxPhotos : photoURLs.count
        
        stack.performBackgroundBatchOperation {_ in 
            for i in 0..<photosCount {
                let photo = Photo(imageUrlString: photoURLs[i], context: self.stack.context)
                photo.pin = self.pin
            }
        }
        
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

extension PhotoAlbumCollectionViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        print("will change")
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            print("insert an item")
            insertedIndexPaths.append(newIndexPath!)
        case .Delete:
            print("delete an item")
            deletedIndexPaths.append(indexPath!)
        case .Update:
            print("update an item")
            updatedIndexPaths.append(indexPath!)
        case .Move:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        print("in cotrollerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        collectionView.performBatchUpdates({
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
        }, completion: nil)
    }
}

extension PhotoAlbumCollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate  {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections![section].numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        configureCell(cell, photo: photo)
        
        return cell
    }
    
    // MARK: - Helpers
    
    func configureCell(cell: PhotoCollectionViewCell, photo: Photo) {
        var image = UIImage(named: "placeholder")
        
        if photo.imageData != nil {
            cell.activityIndicator.hidden = true
            image = UIImage(data: photo.imageData!)
        } else {
            cell.activityIndicator.startAnimating()
            
            let task = FlickrClient.sharedInstance.taskForImageWithUrlString(photo.imageUrlString!) {
                data, error in
                
                guard let data = data,
                    downloadedImage = UIImage(data: data) else {
                        return
                }
                
                photo.imageData = data
                
                // update cell later on main thread
                dispatch_async(dispatch_get_main_queue()) {
                    cell.activityIndicator.stopAnimating()
                    cell.activityIndicator.hidden = true
                    cell.imageView.image = downloadedImage
                }
            }
            
            // any time its value is set, it cancels the previous NSURLSessionTask
            cell.taskToCancelIfCellIsReused = task
        }
        
        cell.imageView.image = image
    }
}
