//
//  TournamentModel.swift
//  StampIt
//
//  Created by ShirakawaToshiaki on 2015/02/24.
//  Copyright (c) 2015年 ShirakawaToshiaki. All rights reserved.
//

import Foundation

class TournamentModel {
    init() {
        let (tb, err) = SD.existingTables()
        if !contains(tb, "tournaments") {
            if let err = SD.createTable("tournaments",
                withColumnNamesAndTypes: [
                    "db_id":        .IntVal,
                    "name":         .StringVal,
                    "beacon_major": .IntVal,
                    "started_at":   .StringVal,
                    "ended_at":     .StringVal,
                    "deleted":      .BoolVal,
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
    
    func add(db_id:Int, name:String, beacon_major:Int, started_at:String, ended_at:String, deleted:Bool, created_at:String, updated_at:String) -> Int{
        var result: Int? = nil
        if let err = SD.executeChange("INSERT INTO tournaments (db_id, name, beacon_major, started_at, ended_at, deleted, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", withArgs: [db_id, name, beacon_major, started_at, ended_at, deleted, created_at, updated_at]) {
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
        if let err = SD.executeChange("DELETE FROM tournaments WHERE ID = ?", withArgs: [id]) {
            //there was an error during the insert, handle it here
            return false
        } else {
            //no error, the row was inserted successfully
            return true
        }
    }

    func getAll() -> NSMutableArray {
        var result = NSMutableArray()
        let (resultSet, err) = SD.executeQuery("SELECT * FROM tournaments ORDER BY ID DESC")
        let dateFormatter = NSDateFormatter()
        if err != nil {
            
        } else {
            result = self.resultDataSetup(resultSet)
        }
        return result
    }
    
    func findByTournamentId(tournament_id:Int) -> NSMutableArray {
        var result = NSMutableArray()
        let (resultSet, err) = SD.executeQuery("SELECT * FROM tournaments WHERE db_id = ? ORDER BY ID DESC", withArgs:[tournament_id])
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
                let db_id        = row["db_id"]?.asInt()!
                let name         = row["name"]?.asString()!
                let beacon_major = row["beacon_major"]?.asInt()!
                let started_at   = row["started_at"]?.asString()!
                let ended_at     = row["ended_at"]?.asString()!
                let deleted      = row["deleted"]?.asBool()!
                let created_at   = row["created_at"]?.asString()!
                let updated_at   = row["updated_at"]?.asString()!
                
                let dic = ["ID":id, "db_id": db_id!, "name": name!, "beacon_major": beacon_major!, "started_at": started_at!, "ended_at": ended_at!, "deleted": deleted!, "created_at": created_at!, "updated_at": updated_at!]
                result.addObject(dic)
            }
        }
        
        return result
    }
}