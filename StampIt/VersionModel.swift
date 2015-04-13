//
//  VersionModel.swift
//  StampIt
//
//  Created by ShirakawaToshiaki on 2015/03/13.
//  Copyright (c) 2015年 ShirakawaToshiaki. All rights reserved.
//

import Foundation

class VersionModel {
    init() {
        let (tb, err) = SD.existingTables()
        if !contains(tb, "version") {
            if let err = SD.createTable("version",
                withColumnNamesAndTypes: [
                    "version_str":         .StringVal,
                ]) {
                    
                    //there was an error during this function, handle it here
            } else {
                //no error, the table was created successfully
            }
        }
        println(SD.databasePath())
    }
    
    func set(version_str:String) -> Int{
        var sel_result = NSMutableArray()
        let (resultSet, err) = SD.executeQuery("SELECT * FROM version ORDER BY ID DESC")
        let dateFormatter = NSDateFormatter()

        if err != nil {
            return 0
        } else {
            sel_result = self.resultDataSetup(resultSet)
        }

        var upd_result: Int? = nil

        if sel_result.count > 0 {
            if let err = SD.executeChange("UPDATE version SET version_str = ?"
                , withArgs: [version_str]) {
                //there was an error during the insert, handle it here
            } else {
                //no error, the row was inserted successfully
                let (id, err) = SD.lastInsertedRowID()
                if err != nil {
                    //err
                }else{
                    //ok
                    upd_result = Int(id)
                }
            }
        } else {
            if let err = SD.executeChange("INSERT INTO version (version_str) VALUES (?)", withArgs: [version_str]) {
                //there was an error during the insert, handle it here
            } else {
                //no error, the row was inserted successfully
                let (id, err) = SD.lastInsertedRowID()
                if err != nil {
                    //err
                }else{
                    //ok
                    upd_result = Int(id)
                }
            }
        }
        
        return upd_result!
    }
    
    func getVersion() -> String {
        var result = NSMutableArray()
        let (resultSet, err) = SD.executeQuery("SELECT * FROM version ORDER BY ID DESC")
        let dateFormatter = NSDateFormatter()
        if err != nil {
            
        } else {
            result = self.resultDataSetup(resultSet)
        }

        if result.count > 0 {
            return result[0]["version_str"] as! String!
        } else {
            return ""
        }
    }
    
    func resultDataSetup(resultSet:[SwiftData.SDRow]) -> NSMutableArray {
        var result = NSMutableArray()
        
        for row in resultSet {
            if let id = row["ID"]?.asInt() {
                let version_str   = row["version_str"]?.asString()!

                let dic = ["version_str":version_str!]
                result.addObject(dic)
            }
        }
        
        return result
    }
}