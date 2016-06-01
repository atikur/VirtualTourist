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
    
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    // MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        loadMapData()
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
}

extension TravelLocationsMapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = mapView.centerCoordinate
        let span = mapView.region.span
        
        saveMapData(center, regionSpan: span)
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