//
//  ViewController.swift
//  StampIt
//
//  Created by ShirakawaToshiaki on 2015/03/30.
//  Copyright (c) 2015年 ShirakawaToshiaki. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    var appDelegate:AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    @IBOutlet weak var collectionView: UICollectionView!
    var immidiate_image:UIImage?
    var greenImageList:[UIImage] = []
    var yellowImageList:[UIImage] = []
    var greenFiles = ["green100.png","green90.png","green80.png","green70.png","green60.png","green50.png","green40.png","green50.png","green60.png","green70.png","green80.png","green90.png"]
    var yellowFiles = ["yellow100.png","yellow90.png","yellow80.png","yellow70.png","yellow60.png","yellow50.png","yellow40.png","yellow50.png","yellow60.png","yellow70.png","yellow80.png","yellow90.png"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        appDelegate.stampViewController = self
        self.immidiate_image = UIImage(named: "sumi.png")

        for filename in self.greenFiles
        {
            var img:UIImage = UIImage(named: filename)!
            self.greenImageList.append(img)
        }
        for filename in self.yellowFiles
        {
            var img:UIImage = UIImage(named: filename)!
            self.yellowImageList.append(img)
        }
    
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell:CustomCell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath) as! CustomCell
        
        cell.image.backgroundColor = UIColor.whiteColor()
        cell.image.clipsToBounds = true

        var index:Int = indexPath.row
        println(index)
        var max_proximity = appDelegate.stamps[index]["max_proximity"] as! Int
        var now_proximity = appDelegate.stamps[index]["now_proximity"] as! Int
        var stamp_id = appDelegate.stamps[index]["stamp_id"] as! Int
        
        if max_proximity == proximity_immediate {
            cell.icon.image = self.immidiate_image
        } else if now_proximity == proximity_near {
            cell.icon.animationImages = self.yellowImageList
            cell.icon.animationRepeatCount = 0
            cell.icon.animationDuration = 0.5
            cell.icon.startAnimating()
            
        } else if now_proximity == proximity_far {
            cell.icon.animationImages = self.greenImageList
            cell.icon.animationRepeatCount = 0
            cell.icon.animationDuration = 1.5
            cell.icon.startAnimating()
            
        } else {
            cell.icon.stopAnimating()
            cell.icon.animationImages = []
            cell.icon.image = nil
        }

        cell.activeIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        cell.activeIndicatorView.hidesWhenStopped = true
        cell.activeIndicatorView.startAnimating()
        
        let path = NSBundle.mainBundle().pathForResource("Info", ofType: "plist")
        let dict = NSDictionary(contentsOfFile: path!)
        
        cell.title.text = appDelegate.stamps[indexPath.row]["stamp_name"] as! String!

        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        let filePath = "\(documentsPath)/img/\(stamp_id)"
        let fileManager:NSFileManager = NSFileManager.defaultManager()
        var err:NSErrorPointer = nil
        
        if fileManager.fileExistsAtPath(filePath) {
            cell.image.image = UIImage(contentsOfFile: filePath)
        } else {
            cell.image.image = UIImage(named: "noimage.png")
        }
        
/*
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        let url:String = String(format: "http://stampit.mag-system-dev.com/api/v1/stamp_image/%d", appDelegate.stamps[indexPath.row]["stamp_id"] as Int)
        
        dispatch_async(dispatch_get_global_queue(priority, 0), {()->() in
            var image = UIImage(data: NSData(contentsOfURL: NSURL(string: url)!)!)
            
            dispatch_async(dispatch_get_main_queue(), {
                cell.image.image = image
                cell.activeIndicatorView.stopAnimating()

            })
        })
*/
        
        cell.backgroundColor = UIColor.blackColor()
        return cell
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.appDelegate.stamps.count;
    }
}

