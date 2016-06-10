//
//  FlickrClient+Convenience.swift
//  VirtualTourist
//
//  Created by Atikur Rahman on 6/3/16.
//  Copyright © 2016 Atikur Rahman. All rights reserved.
//

import MapKit

extension FlickrClient {
    
    func getPhotosForLocation(location: CLLocationCoordinate2D, completionHandler: (photoUrls: [String]?, errorString: String?) -> Void) {
        
        let methodParameters: [String: String] = [
            FlickParameterKeys.Method: FlickParameterValues.MethodSearch,
            FlickParameterKeys.APIKey: FlickParameterValues.APIKey,
            FlickParameterKeys.Accuracy: FlickParameterValues.AccuracyStreet,
            FlickParameterKeys.SafeSearch: FlickParameterValues.SafeSearchEnable,
            FlickParameterKeys.Latitude: "\(location.latitude)",
            FlickParameterKeys.Longitude: "\(location.longitude)",
            FlickParameterKeys.Extras: FlickParameterValues.ExtrasMediumURL,
            FlickParameterKeys.Format: FlickParameterValues.FormatJSON,
            FlickParameterKeys.NoJSONCallback: FlickParameterValues.NoJSONCallbackEnable
        ]
        
        let url = flickrURLFromParameters(methodParameters)
        let request = NSURLRequest(URL: url)
        
        taskForRequest(request) {
            result, error in
            
            guard error == nil else {
                completionHandler(photoUrls: nil, errorString: error?.localizedDescription)
                return
            }
            
            guard let result = result,
                photosDict = result[FlickResponseKeys.PhotosDictionary] as? [String: AnyObject],
                photoArray = photosDict[FlickResponseKeys.PhotoArray] as? [[String: AnyObject]] else {
                    
                    completionHandler(photoUrls: nil, errorString: "Can't get photos. Try again later.")
                    return
            }
            
            var photoURLs = [String]()
            
            for item in photoArray {
                if let urlStr = item[FlickResponseKeys.MediumURL] as? String {
                    photoURLs.append(urlStr)
                }
            }
            
            guard !photoURLs.isEmpty else {
                completionHandler(photoUrls: nil, errorString: "No photos available for this location.")
                return
            }
            
            completionHandler(photoUrls: photoURLs, errorString: nil)
        }
    }
    
    // MARK: - Helpers
    
    private func flickrURLFromParameters(parameters: [String: AnyObject]) -> NSURL {
        let components = NSURLComponents()
        components.scheme = Flickr.APIScheme
        components.host = Flickr.APIHost
        components.path = Flickr.APIPath
        components.queryItems = [NSURLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.URL!
    }
    
}
