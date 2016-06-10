//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Atikur Rahman on 6/2/16.
//  Copyright © 2016 Atikur Rahman. All rights reserved.
//

import Foundation

class FlickrClient: NSObject {
    
    // MARK: - Properties
    
    let session = NSURLSession.sharedSession()
    
    // MARK: -
    
    func taskForRequest(request: NSURLRequest, completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        let task = session.dataTaskWithRequest(request) {
            data, response, error in
            
            func sendError(errorString: String) {
                let userInfo = [NSLocalizedDescriptionKey: errorString]
                completionHandler(result: nil, error: NSError(domain: "taskForHTTTPRequest", code: 1, userInfo: userInfo))
            }
            
            guard error == nil else {
                completionHandler(result: nil, error: error)
                return
            }
            
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode
                where statusCode >= 200 && statusCode <= 299 else {
                    sendError("Your request returned a status code other than 2xx!")
                    return
            }
            
            self.parseDataWithCompletionHandler(data, completionHandler: completionHandler)
        }
        
        task.resume()
        
        return task
    }
    
    func taskForImageWithUrlString(urlString: String, completionHandler: (data: NSData?, error: NSError?) -> Void) -> NSURLSessionTask {
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        let task = session.dataTaskWithRequest(request) {
            data, response, error in
            
            guard let data = data else {
                completionHandler(data: nil, error: error)
                return
            }
            
            completionHandler(data: data, error: nil)
        }
        
        task.resume()
        
        return task
    }
    
    // MARK: - Helpers
    
    private func parseDataWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        do {
            let parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            completionHandler(result: parsedResult, error: nil)
        } catch {
            let userInfo = [NSLocalizedDescriptionKey: "Could not parse the data as JSON"]
            completionHandler(result: nil, error: NSError(domain: "parseDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
    }
    
    // MARK: - Singleton
    
    static let sharedInstance = FlickrClient()
    
    private override init() {}
}
