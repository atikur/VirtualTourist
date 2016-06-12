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
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    
    let maxNumberOfPhotos = 21
    
    let coreDataStack = (UIApplication.sharedApplication().delegate as! AppDelegate).stack
    
    // keep track of changes made to Core Data
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    // keeps track of all the selected indexPaths
    var selectedIndexPaths = [NSIndexPath]() {
        didSet {
            bottomButton.title = selectedIndexPaths.isEmpty ? "New Collection" : "Remove Selected Pictures"
        }
    }
    
    var pin: Pin!
    var fetchedResultsController: NSFetchedResultsController!
    
    // MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        infoLabel.hidden = true
        activityIndicator.hidden = true
        
        configureMapView()
        configureFlowLayout(view.frame.size.width)
        
        // no saved photos found, need to download
        if fetchAllPhotos().isEmpty {
            downloadPhotos()
        }
    }
    
    // MARK: - Actions
    
    @IBAction func bottomButtonPressed(sender: UIBarButtonItem) {
    }
    
    // MARK: - Fetch Photos
    
    // fetch photos from Core Data
    func fetchAllPhotos() -> [Photo] {
        var photos = [Photo]()
        
        // create fetch request
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        
        // create predicate
        let predicate = NSPredicate(format: "pin = %@", pin)
        fetchRequest.predicate = predicate
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: coreDataStack.context , sectionNameKeyPath: nil, cacheName: nil)
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
    
    // MARK: - Download Photos
    
    func downloadPhotos() {
        bottomButton.enabled = false
        showActivityIndicator(true)
        
        FlickrClient.sharedInstance.getPhotosForLocation(pin.coordinate) {
            photoURLs, errorString in
            
            guard let photoURLs = photoURLs else {
                self.displayError(errorString)
                return
            }
            
            self.insertPhotos(photoURLs)
        }
    }
    
    func insertPhotos(photoURLs: [String]) {
        let photosCount = photoURLs.count > maxNumberOfPhotos ? maxNumberOfPhotos : photoURLs.count
        
        // insert new Photos in Core Data (with imageUrlString and empty imageData)
        coreDataStack.performBackgroundBatchOperation {_ in
            for i in 0..<photosCount {
                let photo = Photo(imageUrlString: photoURLs[i], context: self.coreDataStack.context)
                photo.pin = self.pin
            }
            self.coreDataStack.save()
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.showActivityIndicator(false)
            self.bottomButton.enabled = true
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
    
    // MARK: -
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        if toInterfaceOrientation.isLandscape {
            configureFlowLayout(max(view.frame.size.width, view.frame.size.height))
        } else {
            configureFlowLayout(min(view.frame.size.width, view.frame.size.height))
        }
    }
    
    // MARK: - Configure UI
    
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
        let minLineSpacing: CGFloat = 3.0
        let minInterItemSpacing: CGFloat = 3.0
        
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
}

extension PhotoAlbumCollectionViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        // WORKAROUND for crash issue [when updating non-visible collection view with asynchronous operation]
        // https://devforums.apple.com/message/908659#908659
        collectionView.numberOfSections()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
        case .Delete:
            deletedIndexPaths.append(indexPath!)
        case .Update:
            updatedIndexPaths.append(indexPath!)
        case .Move:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        collectionView.performBatchUpdates({
            self.collectionView.deleteItemsAtIndexPaths(self.deletedIndexPaths)
            self.collectionView.insertItemsAtIndexPaths(self.insertedIndexPaths)
            self.collectionView.reloadItemsAtIndexPaths(self.updatedIndexPaths)
            
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
        
        configureCell(cell, forIndexPath: indexPath, withPhoto: photo)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        // allow users to select cells with image
        guard photo.imageData != nil else {
            return
        }
        
        if let index = selectedIndexPaths.indexOf(indexPath) {
            selectedIndexPaths.removeAtIndex(index)
        } else {
            selectedIndexPaths.append(indexPath)
        }
        
        configureCellSelection(cell, indexPath: indexPath)
    }
    
    // MARK: - Helpers
    
    func configureCell(cell: PhotoCollectionViewCell, forIndexPath indexPath: NSIndexPath, withPhoto photo: Photo) {
        var image = UIImage(named: "placeholder")
        
        cell.imageView.image = nil
        
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
                self.coreDataStack.save()
                
                // update cell later on main thread
                dispatch_async(dispatch_get_main_queue()) {
                    // make sure cell for the item is still visible
                    if let updateCell = self.collectionView.cellForItemAtIndexPath(indexPath) as? PhotoCollectionViewCell {
                        updateCell.activityIndicator.stopAnimating()
                        updateCell.activityIndicator.hidden = true
                        updateCell.imageView.image = downloadedImage
                    }
                }
            }
            
            // any time its value is set, it cancels the previous NSURLSessionTask
            cell.taskToCancelIfCellIsReused = task
        }

        cell.imageView.image = image
        
        configureCellSelection(cell, indexPath: indexPath)
    }
    
    func configureCellSelection(cell: PhotoCollectionViewCell, indexPath: NSIndexPath) {
        if let _ = selectedIndexPaths.indexOf(indexPath) {
            cell.alpha = 0.3
        } else {
            cell.alpha = 1.0
        }
    }
}
