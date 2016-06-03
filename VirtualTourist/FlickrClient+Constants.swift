//
//  FlickrClient+Constants.swift
//  VirtualTourist
//
//  Created by Atikur Rahman on 6/3/16.
//  Copyright © 2016 Atikur Rahman. All rights reserved.
//

extension FlickrClient {
    
    struct FlickParameterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let Accuracy = "accuracy"
        static let SafeSearch = "safe_search"
        static let Latitude = "lat"
        static let Longitude = "lon"
        static let Extras = "extras"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
    }
    
    struct FlickParameterValues {
        static let MethodSearch = "flickr.photos.search"
        static let APIKey = "f9acf8aa4c2fa6b24b853ff173146f5b"
        static let AccuracyStreet = "16"
        static let SafeSearchEnable = "1"
        static let ExtrasMediumURL = "url_m"
        static let FormatJSON = "json"
        static let NoJSONCallbackEnable = "1"
    }
    
    struct FlickResponseKeys {
        static let PhotosDictionary = "photos"
        static let PhotoArray = "photo"
        static let Pages = "pages"
        static let Status = "stat"
        static let MediumURL = "url_m"
    }
    
    struct FlickrResponseValues {
        static let StatusOK = "ok"
    }
}
