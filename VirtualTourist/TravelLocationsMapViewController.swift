//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Atikur Rahman on 6/1/16.
//  Copyright © 2016 Atikur Rahman. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController {
    
    // MARK: - Properties
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var bottomInfoView: UIView!
    @IBOutlet weak var editBarButton: UIBarButtonItem!
    
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    var isEditModeEnabled = false {
        didSet {
            editBarButton.title = isEditModeEnabled ? "Done" : "Edit"
            bottomInfoView.hidden = !isEditModeEnabled
        }
    }
    
    var fetchedResultsController: NSFetchedResultsController!
    
    // MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        isEditModeEnabled = false
        
        addGestureRecognizer()
        loadMapData()
        
        loadPins()
    }
    
    func loadPins() {
        let stack = (UIApplication.sharedApplication().delegate as! AppDelegate).stack
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "latitude", ascending: true)
        ]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController?.delegate = self
        do {
            try fetchedResultsController.performFetch()
            guard let pins = fetchedResultsController.fetchedObjects as? [Pin] else {
                return
            }
            for pin in pins {
                addAnnotation(pin.coordinate)
            }
            
        } catch {
            print("Error while trying to perform a search.")
        }
    }
    
    @IBAction func editBarButtonTapped(sender: UIBarButtonItem) {
        isEditModeEnabled = !isEditModeEnabled
    }
    
    func addGestureRecognizer() {
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(TravelLocationsMapViewController.longPressDetected(_:)))
        longPressRecognizer.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecognizer)
    }
    
    func longPressDetected(gestureRecognizer: UIGestureRecognizer) {
        guard !isEditModeEnabled else {
            return
        }
        
        if gestureRecognizer.state == .Began {
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let mapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            
            let pin = Pin(coordinate: mapCoordinate, context: fetchedResultsController.managedObjectContext)
            print("Adding new pin at coordinate: \(pin.coordinate)")
        }
    }
    
    func addAnnotation(coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
    // MARK: - Save/Load Map Data
    
    func loadMapData() {
        guard userDefaults.boolForKey(UserDefaultKeys.IsAppLaunchedBefore) else {
            userDefaults.setBool(true, forKey: UserDefaultKeys.IsAppLaunchedBefore)
            userDefaults.synchronize()
            return
        }
        
        let centerCoordinate = CLLocationCoordinate2D(latitude: userDefaults.doubleForKey(UserDefaultKeys.CenterLatitude), longitude: userDefaults.doubleForKey(UserDefaultKeys.CenterLongitude))
        let regionSpan = MKCoordinateSpanMake(userDefaults.doubleForKey(UserDefaultKeys.SpanLatitudeDelta), userDefaults.doubleForKey(UserDefaultKeys.SpanLongitudeDelta))
        
        let region = MKCoordinateRegion(center: centerCoordinate, span: regionSpan)
        mapView.setRegion(region, animated: true)
    }
    
    func saveMapData(centerCoordinate: CLLocationCoordinate2D, regionSpan: MKCoordinateSpan) {
        userDefaults.setDouble(centerCoordinate.latitude, forKey: UserDefaultKeys.CenterLatitude)
        userDefaults.setDouble(centerCoordinate.longitude, forKey: UserDefaultKeys.CenterLongitude)
        
        userDefaults.setDouble(regionSpan.latitudeDelta, forKey: UserDefaultKeys.SpanLatitudeDelta)
        userDefaults.setDouble(regionSpan.longitudeDelta, forKey: UserDefaultKeys.SpanLongitudeDelta)
        
        userDefaults.synchronize()
    }
    
    // MARK: -
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowPhotoAlbum" {
            let destinationVC = segue.destinationViewController as! PhotoAlbumCollectionViewController
            destinationVC.annoation = sender as! MKAnnotation
        }
    }
    
    // MARK: -
    
    func fetchedResultsChangeInsert(anObject: AnyObject) {
        guard let pin = anObject as? Pin else {
            return
        }
        
        addAnnotation(pin.coordinate)
        print("added")
    }
    
    func fetchedResultsChangeDelete(anObject: AnyObject) {
        guard let pin = anObject as? Pin else {
            return
        }
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = pin.coordinate
        mapView.removeAnnotation(annotation)
        print("removed")
    }
    
    func fetchedResultsChangeMove(anObject: AnyObject) {
        print("move object")
    }
    
    func fetchedResultsChangeUpdate(anObject: AnyObject) {
        print("update object")
    }
}

extension TravelLocationsMapViewController: NSFetchedResultsControllerDelegate {
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            fetchedResultsChangeInsert(anObject)
        case .Delete:
            fetchedResultsChangeDelete(anObject)
        case .Update:
            fetchedResultsChangeUpdate(anObject)
        case .Move:
            fetchedResultsChangeMove(anObject)
        }
    }
    
}

extension TravelLocationsMapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = mapView.centerCoordinate
        let span = mapView.region.span
        
        saveMapData(center, regionSpan: span)
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        guard let annotation = view.annotation else {
            return
        }
        
        if isEditModeEnabled {
            mapView.removeAnnotation(annotation)
        } else {
            performSegueWithIdentifier("ShowPhotoAlbum", sender: annotation)
        }
    }
}

extension TravelLocationsMapViewController {
    
    struct UserDefaultKeys {
        static let IsAppLaunchedBefore = "isAppLaunchedBefore"
        static let SpanLatitudeDelta = "spanLatitudeDelta"
        static let SpanLongitudeDelta = "spanLongitudeDelta"
        static let CenterLatitude = "centerLatitude"
        static let CenterLongitude = "centerLongitude"
    }
}