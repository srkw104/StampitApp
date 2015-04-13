//
//  StampModel.swift
//  StampIt
//
//  Created by ShirakawaToshiaki on 2015/02/24.
//  Copyright (c) 2015年 ShirakawaToshiaki. All rights reserved.
//

import Foundation

class StampModel {
    init() {
        let (tb, err) = SD.existingTables()
        if !contains(tb, "stamps") {
            if let err = SD.createTable("stamps",
                withColumnNamesAndTypes: [
                    "db_id":         .IntVal,
                    "tournament_id": .IntVal,
                    "name":          .StringVal,
                    "beacon_minor":  .IntVal,
                    "latitude":      .DoubleVal,
                    "longitude":     .DoubleVal,
                    "deleted":       .BoolVal,
                    "created_at":   .StringVal,
                    "updated_at":   .StringVal
                ]) {
                    
                    //there was an error during this function, handle it here
            } else {
                //no error, the table was created successfully
            }
        }
        println(SD.databasePath())
    }
    
    func add(db_id:Int, tournament_id:Int, name:String, beacon_minor:Int, latitude:Double, longitude:Double, deleted:Bool, created_at:String, updated_at:String) -> Int{
        var result: Int? = nil
        if let err = SD.executeChange("INSERT INTO stamps (db_id, tournament_id, name, beacon_minor, latitude, longitude, deleted, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", withArgs: [db_id, tournament_id, name, beacon_minor, latitude, longitude, deleted, created_at, updated_at]) {
            //there was an error during the insert, handle it here
        } else {
            //no error, the row was inserted successfully
            let (id, err) = SD.lastInsertedRowID()
            if err != nil {
                //err
            }else{
                //ok
                result = Int(id)
            }
        }
        return result!
    }
    
    func delete(id:Int) -> Bool {
        if let err = SD.executeChange("DELETE FROM stamps WHERE ID = ?", withArgs: [id]) {
            //there was an error during the insert, handle it here
            return false
        } else {
            //no error, the row was inserted successfully
            return true
        }
    }
    
    func getAll() -> NSMutableArray {
        var result = NSMutableArray()
        let (resultSet, err) = SD.executeQuery("SELECT * FROM stamps ORDER BY ID DESC")
        let dateFormatter = NSDateFormatter()
        if err != nil {
            
        } else {
            result = self.resultDataSetup(resultSet)
        }
        return result
    }
    
    func findByTournamentId(tournament_id:Int) -> NSMutableArray {
        var result = NSMutableArray()
        let (resultSet, err) = SD.executeQuery("SELECT * FROM stamps WHERE tournament_id = ? ORDER BY db_id ASC", withArgs:[tournament_id])
        let dateFormatter = NSDateFormatter()
        if err != nil {
            
        } else {
            result = self.resultDataSetup(resultSet)
        }
        return result
    }
    
    func resultDataSetup(resultSet:[SwiftData.SDRow]) -> NSMutableArray {
        var result = NSMutableArray()
        
        for row in resultSet {
            if let id = row["ID"]?.asInt() {
                let db_id         = row["db_id"]?.asInt()!
                let tournament_id = row["tournament_id"]?.asInt()!
                let name          = row["name"]?.asString()!
                let beacon_minor  = row["beacon_minor"]?.asInt()!
                let latitude      = row["latitude"]?.asDouble()!
                let longitude     = row["longitude"]?.asDouble()!
                let deleted       = row["deleted"]?.asBool()!
                let created_at    = row["created_at"]?.asString()!
                let updated_at    = row["updated_at"]?.asString()!
                
                let dic = ["ID":id, "db_id": db_id!, "tournament_id": tournament_id!, "name": name!, "beacon_minor": beacon_minor!, "latitude": latitude!, "longitude": longitude!, "deleted": deleted!, "created_at": created_at!, "updated_at": updated_at!]
                result.addObject(dic)
            }
        }
        
        return result
    }
}