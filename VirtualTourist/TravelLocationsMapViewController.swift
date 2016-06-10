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
    
    // MARK: - Outlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var bottomInfoView: UIView!
    @IBOutlet weak var editBarButton: UIBarButtonItem!
    
    // MARK: - Properties
    
    let userDefaults = NSUserDefaults.standardUserDefaults()
    let stack = (UIApplication.sharedApplication().delegate as! AppDelegate).stack
    
    var isEditModeEnabled = false {
        didSet {
            editBarButton.title = isEditModeEnabled ? "Done" : "Edit"
            bottomInfoView.hidden = !isEditModeEnabled
        }
    }
    
    // MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.addAnnotations(fetchAllPins())
    
        isEditModeEnabled = false
        
        loadMapWithSavedRegion()
        addGestureRecognizer()
    }
    
    // MARK: - Actions
    
    @IBAction func editBarButtonTapped(sender: UIBarButtonItem) {
        isEditModeEnabled = !isEditModeEnabled
    }
    
    // MARK: - Drop Pin
    
    // drop a pin when user performs a long press
    func longPressDetected(gestureRecognizer: UIGestureRecognizer) {
        // user can't drop a pin in `Edit` mode
        guard !isEditModeEnabled else {
            return
        }
        
        if gestureRecognizer.state == .Began {
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let mapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            
            let pin = Pin(coordinate: mapCoordinate, context: stack.context)
            stack.save()
            
            mapView.addAnnotation(pin)
        }
    }
    
    // MARK: - Save/Load Map Data
    
    // get pins from CoreData
    func fetchAllPins() -> [Pin] {
        var pins = [Pin]()
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        do {
            let results = try stack.context.executeFetchRequest(fetchRequest)
            if let results = results as? [Pin] {
                pins = results
            }
        } catch {
            print("Error while trying to fetch pins.")
        }
        
        return pins
    }
    
    // retrieve center coordinate and span from NSUserDefaults
    func loadMapWithSavedRegion() {
        // if it is first app launch, data isn't available
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
    
    // save center coordinate and span to NSUserDefaults
    func saveMapRegionData(centerCoordinate: CLLocationCoordinate2D, regionSpan: MKCoordinateSpan) {
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
            destinationVC.pin = sender as! Pin
        }
    }
    
    func addGestureRecognizer() {
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(TravelLocationsMapViewController.longPressDetected(_:)))
        longPressRecognizer.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecognizer)
    }
}

extension TravelLocationsMapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = mapView.centerCoordinate
        let span = mapView.region.span
        
        saveMapRegionData(center, regionSpan: span)
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        guard let pin = view.annotation as? Pin else {
            return
        }
        
        if isEditModeEnabled {
            mapView.removeAnnotation(pin)
            stack.context.deleteObject(pin)
        } else {
            mapView.deselectAnnotation(pin, animated: false)
            performSegueWithIdentifier("ShowPhotoAlbum", sender: pin)
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