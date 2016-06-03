//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Atikur Rahman on 6/1/16.
//  Copyright © 2016 Atikur Rahman. All rights reserved.
//

import UIKit
import MapKit

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
    
    // MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        isEditModeEnabled = false
        
        addGestureRecognizer()
        loadMapData()
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
            
            addAnnotation(mapCoordinate)
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