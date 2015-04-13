//
//  AppDelegate.swift
//  StampIt
//
//  Created by ShirakawaToshiaki on 2015/03/02.
//  Copyright (c) 2015年 ShirakawaToshiaki. All rights reserved.
//

import UIKit
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {
    
    var window: UIWindow?
    var stampViewController: ViewController!
    
    var manager: CLLocationManager!
    var proximityUUID: NSUUID!
    var region: CLBeaconRegion!
    
    var stamps = [[String:AnyObject]]()
    var version:String = ""
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: UIUserNotificationType.Badge | UIUserNotificationType.Sound | UIUserNotificationType.Alert, categories: nil))
        
        UIApplication.sharedApplication().cancelAllLocalNotifications();
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: UIUserNotificationType.Sound | UIUserNotificationType.Alert | UIUserNotificationType.Badge, categories: nil))
        
        
        let path = NSBundle.mainBundle().pathForResource("Info", ofType: "plist")
        let dict = NSDictionary(contentsOfFile: path!)
        let UUID: String = dict?.objectForKey("Beacon uuid") as! String
        let BEACON_IDENTIFER: String = dict?.objectForKey("Beacon identifer") as! String
        
        self.manager = CLLocationManager()
        self.manager.delegate = self
        self.proximityUUID = NSUUID(UUIDString: UUID)
        
        // セキュリティ認証のステータスを取得
        let status = CLLocationManager.authorizationStatus()
        
        // まだ認証が得られていない場合は、認証ダイアログを表示
        if(status == CLAuthorizationStatus.NotDetermined) {
            
            // まだ承認が得られていない場合は、認証ダイアログを表示
            self.manager.requestAlwaysAuthorization();
        }
        
        self.region = CLBeaconRegion(proximityUUID:self.proximityUUID, identifier:BEACON_IDENTIFER)
        self.region.notifyOnEntry = true
        self.region.notifyOnExit  = true
        self.region.notifyEntryStateOnDisplay = false
        
        self.manager.startMonitoringForRegion(self.region)
        
        if launchOptions?.indexForKey(UIApplicationLaunchOptionsLocationKey) != nil {
            self.sendNotification("bg")
        }
        
        self.databaseInit()
        
        if self.isVersionUp() {
            println("upper version exists")
            self.databaseSetup()
        } else {
            println("current version")
        }
        
        self.getStamps()
        
        if (launchOptions != nil) {
            var notification:UILocalNotification? = launchOptions!.indexForKey(UIApplicationLaunchOptionsLocalNotificationKey) as? UILocalNotification
            if (notification != nil) {
                //notificationを実行します
                var alert = UIAlertView()
                alert.title = "Check It!"
                alert.message = notification!.alertBody
                alert.addButtonWithTitle(notification!.alertAction!)
                alert.show()
                
                UIApplication.sharedApplication().cancelLocalNotification(notification!);
            }
        }
        return true
    }
    
    func databaseInit() {
        var _tournament = TournamentModel()
        var _stamp      = StampModel()
        var _history    = HistoryModel()
        
        var tournaments = _tournament.getAll()
        var stamps = _stamp.getAll()
        var history = _history.getAll()
        /*
        for h in history {
        _history.delete(h["ID"] as Int)
        }
        */
    }
    
    func databaseSetup() {
        let path = NSBundle.mainBundle().pathForResource("Info", ofType: "plist")
        let dict = NSDictionary(contentsOfFile: path!)
        let tournament_id: String = dict?.objectForKey("Tournament ID") as! String
        
        // 通信先のURLを生成.
        var myUrl:NSURL = NSURL(string:"http://stampit.mag-system-dev.com/api/v1/stamps/" + tournament_id)!
        // リクエストを生成.
        var myRequest:NSURLRequest  = NSURLRequest(URL: myUrl)
        
        var myResponse:NSURLResponse?
        // 送信処理を始める.
        var res = NSURLConnection.sendSynchronousRequest(myRequest, returningResponse: &myResponse, error: nil)
        
        if let httpResponse = myResponse as? NSHTTPURLResponse {
            println("status: \(httpResponse.statusCode)")
        }
        
        if (res == nil) {
            println("database setup failed.")
            return
        }
        
        self.tournamentSetup(tournament_id)
        self.stampSetup(tournament_id)
        self.getPhotos()
        
        self.versionWrite()
    }
    
    func tournamentSetup(tournament_id:String) {
        // 通信先のURLを生成.
        var myUrl:NSURL = NSURL(string:"http://stampit.mag-system-dev.com/api/v1/tournaments/" + tournament_id)!
        // リクエストを生成.
        var myRequest:NSURLRequest  = NSURLRequest(URL: myUrl)
        
        var myResponse:NSURLResponse?
        // 送信処理を始める.
        var res = NSURLConnection.sendSynchronousRequest(myRequest, returningResponse: &myResponse, error: nil)
        
        if let httpResponse = myResponse as? NSHTTPURLResponse {
            println("status: \(httpResponse.statusCode)")
        }
        
        if (res == nil) {
            println("database setup failed.")
            return
        }
        
        // 帰ってきたデータをJSONに変換.
        var tournament_json:NSString = NSString(data:res!, encoding: NSUTF8StringEncoding)!
        
        if tournament_json.length > 0 {
            var tournament:JSON! = JSON(string: tournament_json as String)
            var _tournament = TournamentModel()
            
            var db_tournaments = _tournament.getAll()
            for t in db_tournaments {
                _tournament.delete(t["ID"] as! Int)
            }

            let db_id        = tournament["id"].asInt!
            let name         = tournament["name"].asString!
            let beacon_major = tournament["beacon_major"].asInt!
            let started_at   = tournament["started_at"].asString!
            let ended_at     = tournament["ended_at"].asString!
            let deleted      = tournament["deleted"].asBool!
            let created_at   = tournament["created_at"].asString!
            let updated_at   = tournament["updated_at"].asString!
            
            _tournament.add(db_id, name: name, beacon_major: beacon_major, started_at: started_at, ended_at: ended_at, deleted: deleted, created_at: created_at, updated_at: updated_at)
        }
    }
    
    func stampSetup(tournament_id:String) {
        // 通信先のURLを生成.
        var myUrl:NSURL = NSURL(string:"http://stampit.mag-system-dev.com/api/v1/stamps/" + tournament_id)!
        // リクエストを生成.
        var myRequest:NSURLRequest  = NSURLRequest(URL: myUrl)
        
        var myResponse:NSURLResponse?
        // 送信処理を始める.
        var res = NSURLConnection.sendSynchronousRequest(myRequest, returningResponse: &myResponse, error: nil)
        
        if let httpResponse = myResponse as? NSHTTPURLResponse {
            println("status: \(httpResponse.statusCode)")
        }
        
        if (res == nil) {
            println("database setup failed.")
            return
        }
        
        // 帰ってきたデータをJSONに変換.
        var stamps_json:NSString = NSString(data:res!, encoding: NSUTF8StringEncoding)!
        
        
        if stamps_json.length > 0 {
            var _stamp      = StampModel()
            var stamps:JSON! = JSON(string: stamps_json as String)

            var db_stamps = _stamp.getAll()
            for s in db_stamps {
                _stamp.delete(s["ID"] as! Int)
            }
            
            for (i, stamp) in stamps {
                let db_id         = stamp["id"].asInt!
                let tournament_id = stamp["tournament_id"].asInt!
                let name          = stamp["name"].asString!
                let beacon_minor  = stamp["beacon_minor"].asInt!
                let latitude      = stamp["latitude"].asDouble!
                let longitude     = stamp["longitude"].asDouble!
                let deleted       = stamp["deleted"].asBool!
                let created_at    = stamp["created_at"].asString!
                let updated_at    = stamp["updated_at"].asString!
                
                _stamp.add(db_id, tournament_id: tournament_id, name: name, beacon_minor: beacon_minor, latitude: latitude, longitude: longitude, deleted: deleted, created_at: created_at, updated_at: updated_at)
            }
        }
    }
    
    func versionWrite() {
        var _version = VersionModel()
        _version.set(self.version)
    }
    
    func getStamps() {
        var _tournament = TournamentModel()
        var _stamp      = StampModel()
        var _history    = HistoryModel()
        
        let path = NSBundle.mainBundle().pathForResource("Info", ofType: "plist")
        let dict = NSDictionary(contentsOfFile: path!)
        let tournament_id_str: String = dict?.objectForKey("Tournament ID") as! String
        let tournament_id: Int = tournament_id_str.toInt()!
        
        var tournaments = _tournament.findByTournamentId(tournament_id)
        var stamps      = _stamp.findByTournamentId(tournament_id)
        
        var result = [[String:AnyObject]]()
        
        for row in stamps {
            let tournament_id:Int      = row["tournament_id"] as! Int
            let stamp_id:Int           = row["db_id"] as! Int
            let tournament_name:String = tournaments[0]["name"] as! String
            let stamp_name:String      = row["name"] as! String
            let beacon_major:Int       = tournaments[0]["beacon_major"] as! Int
            let beacon_minor:Int       = row["beacon_minor"] as! Int
            
            var dic = [String:AnyObject]()
            
            dic["tournament_id"]   = tournament_id
            dic["stamp_id"]        = stamp_id
            dic["tournament_name"] = tournament_name
            dic["stamp_name"]      = stamp_name
            dic["beacon_major"]    = beacon_major
            dic["beacon_minor"]    = beacon_minor
            dic["now_proximity"]   = proximity_unknown
            
            var history = _history.findByTournamentIdStampId(tournament_id, stamp_id: stamp_id)
            
            if history.count > 0 {
                let proximity:Int = history[0]["proximity"] as! Int
                dic["max_proximity"] = proximity
            } else {
                dic["max_proximity"] = proximity_unknown
            }
            
            result.append(dic)
        }
        
        self.stamps = result
    }
    
    func getPhotos() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        let picturePath = documentsPath + "/img"
        let fileManager:NSFileManager = NSFileManager.defaultManager()
        var err:NSErrorPointer = nil
        
        if !fileManager.fileExistsAtPath(picturePath) {
            fileManager.createDirectoryAtPath(picturePath, withIntermediateDirectories: true, attributes: nil, error: err)
        }
        
        var _tournament = TournamentModel()
        var _stamp      = StampModel()
        
        let path = NSBundle.mainBundle().pathForResource("Info", ofType: "plist")
        let dict = NSDictionary(contentsOfFile: path!)
        let tournament_id_str: String = dict?.objectForKey("Tournament ID") as! String
        let tournament_id: Int = tournament_id_str.toInt()!
        
        var stamps      = _stamp.findByTournamentId(tournament_id)
        
        for row in stamps {
            let stampId:Int           = row["db_id"] as! Int
            var pictErr:NSError?
            
            let url_str:String = String(format: "http://stampit.mag-system-dev.com/api/v1/stamp_image/%d", stampId)
            let url = NSURL(string: url_str)
            let data = NSData(contentsOfURL: url!, options: NSDataReadingOptions.DataReadingMappedIfSafe, error: &pictErr)

            if pictErr == nil {
                data?.writeToFile("\(picturePath)/\(stampId)", atomically: true)
            }
        }
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    /*
    (Delegate) リージョン内に入ったというイベントを受け取る.
    */
    func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
        println("didEnterRegion");
        self.manager.startRangingBeaconsInRegion(self.region);
    }
    
    /*
    (Delegate) リージョンから出たというイベントを受け取る.
    */
    func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
        NSLog("didExitRegion");
        self.manager.stopRangingBeaconsInRegion(self.region);
    }
    
    func locationManager(manager: CLLocationManager!, didDetermineState state: CLRegionState, forRegion region: CLRegion!)
    {
        switch(state) {
        case CLRegionState.Inside:
            println("didEnterRegion");
            self.manager.startRangingBeaconsInRegion(self.region);
            break
            
        case CLRegionState.Outside:
            NSLog("didExitRegion!");
            self.manager.stopRangingBeaconsInRegion(self.region);
            break
            
        case CLRegionState.Unknown:
            break
            
        default:
            break
        }
        
    }
    
    
    func locationManager(manager: CLLocationManager!, didRangeBeacons beacons: [AnyObject]!, inRegion region: CLBeaconRegion!) {
        // 範囲内で検知されたビーコンはこのbeaconsにCLBeaconオブジェクトとして格納される
        // rangingが開始されると１秒毎に呼ばれるため、beaconがある場合のみ処理をするようにすること.
        NSLog("didRangeBeacons");
        
        var memo:String = ""
        
        for (var idx = 0; idx < self.stamps.count ; idx++ ) {
            var major:Int         = self.stamps[idx]["beacon_major"] as! Int
            var minor:Int         = self.stamps[idx]["beacon_minor"] as! Int
            var tournament_id:Int = self.stamps[idx]["tournament_id"] as! Int
            var stamp_id:Int      = self.stamps[idx]["stamp_id"] as! Int
            var stamp_name:String = self.stamps[idx]["stamp_name"] as! String
            var max_proximity:Int = self.stamps[idx]["max_proximity"] as! Int
            var now_proximity:Int  = proximity_unknown
            
            println("major: \(major), minor: \(minor)");
            
            
            // 範囲内で検知されたビーコンはこのbeaconsにCLBeaconオブジェクトとして格納される
            // rangingが開始されると１秒毎に呼ばれるため、beaconがある場合のみ処理をするようにすること.
            if(beacons.count > 0){
                
                // STEP7: 発見したBeaconの数だけLoopをまわす
                for var i = 0; i < beacons.count; i++ {
                    
                    var beacon = beacons[i] as! CLBeacon
                    
                    let beaconUUID = beacon.proximityUUID;
                    let minorID = beacon.minor;
                    let majorID = beacon.major;
                    let rssi = beacon.rssi;
                    
                    println("UUID: \(beaconUUID.UUIDString)");
                    println("minorID: \(minorID)");
                    println("majorID: \(majorID)");
                    println("RSSI: \(rssi)");
                    
                    if major == majorID.integerValue && minor == minorID.integerValue {
                        
                        switch (beacon.proximity) {
                        case CLProximity.Unknown:
                            println("Proximity: Unknown");
                            now_proximity = proximity_unknown
                            break;
                            
                        case CLProximity.Far:
                            println("Proximity: Far");
                            now_proximity = proximity_far
                            break;
                            
                        case CLProximity.Near:
                            println("Proximity: Near");
                            now_proximity = proximity_near
                            break;
                            
                        case CLProximity.Immediate:
                            println("Proximity: Immediate");
                            now_proximity = proximity_immediate
                            break;
                        }
                        
                        if max_proximity < now_proximity {
                            var _history    = HistoryModel()
                            var history = _history.findByTournamentIdStampId(tournament_id, stamp_id: stamp_id)
                            
                            if history.count > 0 {
                                _history.updateByTournamentIdStampId(tournament_id, stamp_id: stamp_id, proximity: now_proximity)
                            } else {
                                _history.add(tournament_id, stamp_id: stamp_id, proximity: now_proximity)
                            }
                            
                            self.stamps[idx]["max_proximity"] = now_proximity
                            
                            switch now_proximity {
                            case proximity_far:
                                
                                self.sendNotification("\(stamp_name)が近くにあります")
                                break
                                
                            case proximity_near:
                                
                                self.sendNotification("読み取り機にiPhoneをかざしてください")
                                break
                                
                            case proximity_immediate:
                                
                                self.sendNotification("タッチOK!")
                                break
                                
                            default:
                                break
                            }
                        }
                    }
                }
                
                memo += "[\(major),\(minor)] : \(now_proximity) [\(max_proximity)] \n"
            }
            
            self.stamps[idx]["now_proximity"] = now_proximity
        }
        
        stampViewController.collectionView.reloadData()
    }
    
    func sendNotification(message:String) {
        var notify = UILocalNotification()
        notify.fireDate = NSDate(timeIntervalSinceNow: 0)
        notify.timeZone = NSTimeZone()
        notify.alertBody = message
        notify.alertAction = "Open"
        notify.soundName = UILocalNotificationDefaultSoundName
        UIApplication.sharedApplication().scheduleLocalNotification(notify)
    }
    
    /*
    アプリがアクティブ時の通知
    */
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        /*
        var alert = UIAlertView()
        alert.title = "近いよ？"
        alert.message = notification.alertBody
        alert.addButtonWithTitle(notification.alertAction!)
        alert.show()
        */
    }
    
    /*
    アプリが非アクティブ時（別アプリの表示中など）の通知
    */
    func application(application:UIApplication, handleActionWithIdentifer identifer:String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void) {
        
        var alert = UIAlertView()
        alert.title = "Check it!"
        alert.message = notification.alertBody
        alert.addButtonWithTitle(notification.alertAction!)
        alert.show()
    }
    
    func isVersionUp() -> Bool {
        
        // 通信先のURLを生成.
        var myUrl:NSURL = NSURL(string:"http://stampit.mag-system-dev.com/api/v1/version")!
        // リクエストを生成.
        var myRequest:NSURLRequest  = NSURLRequest(URL: myUrl)
        
        var myResponse:NSURLResponse?
        // 送信処理を始める.
        var res = NSURLConnection.sendSynchronousRequest(myRequest, returningResponse: &myResponse, error: nil)
        
        if let httpResponse = myResponse as? NSHTTPURLResponse {
            println("status: \(httpResponse.statusCode)")
        }
        
        if (res == nil) {
            println("version check failed.")
            return false
        }
        
        // 帰ってきたデータを文字列に変換.
        var server_version:NSString = NSString(data:res!, encoding: NSUTF8StringEncoding)!
        self.version = server_version as String
        
        var _version = VersionModel()
        var local_version:NSString = _version.getVersion()
        
        return (server_version != local_version)
    }
}


