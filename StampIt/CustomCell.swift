//
//  CustomCell.swift
//  StampIt
//
//  Created by ShirakawaToshiaki on 2015/03/30.
//  Copyright (c) 2015年 ShirakawaToshiaki. All rights reserved.
//

import UIKit

class CustomCell: UICollectionViewCell {
    @IBOutlet var title:UILabel!
    @IBOutlet var image:UIImageView!
    @IBOutlet var icon:UIImageView!
    @IBOutlet var activeIndicatorView:UIActivityIndicatorView!
    
    override init(frame: CGRect){
        super.init(frame: frame)
    }
    required init(coder aDecoder: NSCoder){
        super.init(coder: aDecoder)
    }
    
}