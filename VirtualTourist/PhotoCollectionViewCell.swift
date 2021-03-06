//
//  PhotoCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Atikur Rahman on 6/7/16.
//  Copyright © 2016 Atikur Rahman. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // any time its value is set, it cancels the previous NSURLSessionTask
    var taskToCancelIfCellIsReused: NSURLSessionTask? {
        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }
    
}
