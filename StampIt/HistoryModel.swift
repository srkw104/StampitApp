//
//  HistoryModel.swift
//  StampIt
//
//  Created by ShirakawaToshiaki on 2015/02/25.
//  Copyright (c) 2015年 ShirakawaToshiaki. All rights reserved.
//

import Foundation

let proximity_unknown   = 0
let proximity_far       = 1
let proximity_near      = 2
let proximity_immediate = 4

class HistoryModel {
    
    init() {
        let (tb, err) = SD.existingTables()
        if !contains(tb, "histories") {
            if let err = SD.createTable("histories",
                withColumnNamesAndTypes: [
                    "tournament_id": .IntVal,
                    "stamp_id":      .IntVal,
                    "proximity":     .IntVal,
                    "created_at":    .StringVal,
                    "updated_at":    .StringVal
                ]) {
                    
                    //there was an error during this function, handle it here
            } else {
                //no error, the table was created successfully
            }
        }
        println(SD.databasePath())
    }
    
    class func getProximityString(proximity: Int) -> String {
        switch proximity {
        case proximity_unknown:
            return "不明"
        case proximity_far:
            return "反応あり"
        case proximity_near:
            return "近距離"
        case proximity_immediate:
            return "完了"
        default:
            return "不明"
        }
    }

    func add(tournament_id:Int, stamp_id:Int, proximity:Int) -> Int{
        let now = NSDate()
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "jp_JP")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        println("UPDATE histories tournament_id: \(tournament_id), stamp_id: \(stamp_id) - \(proximity)")
        
        var result: Int? = nil
        if let err = SD.executeChange("INSERT INTO histories (tournament_id, stamp_id, proximity, created_at, updated_at) VALUES (?, ?, ?, ?, ?)", withArgs: [tournament_id, stamp_id, proximity, dateFormatter.stringFromDate(now), dateFormatter.stringFromDate(now)]) {
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
    
    func updateByTournamentIdStampId(tournament_id:Int, stamp_id:Int, proximity:Int) -> Int{
        let now = NSDate()
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "jp_JP")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        println("UPDATE histories tournament_id: \(tournament_id), stamp_id: \(stamp_id) - \(proximity)")
        
        var result: Int? = nil
        if let err = SD.executeChange("UPDATE histories set proximity = ?, updated_at = ? WHERE tournament_id = ? AND stamp_id = ?", withArgs: [proximity, dateFormatter.stringFromDate(now), tournament_id, stamp_id]) {
            //there was an error during the insert, handle it here
            println("error UPDATE histories")
            
        } else {
            println("error UPDATE histories")

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
        if let err = SD.executeChange("DELETE FROM histories WHERE ID = ?", withArgs: [id]) {
            //there was an error during the insert, handle it here
            return false
        } else {
            //no error, the row was inserted successfully
            return true
        }
    }
    
    func getAll() -> NSMutableArray {
        var result = NSMutableArray()
        let (resultSet, err) = SD.executeQuery("SELECT * FROM histories ORDER BY ID DESC")
        let dateFormatter = NSDateFormatter()
        if err != nil {
            
        } else {
            result = self.resultDataSetup(resultSet)
        }
        return result
    }
    
    func findByTournamentIdStampId(tournament_id:Int, stamp_id:Int) -> NSMutableArray {
        var result = NSMutableArray()
        let (resultSet, err) = SD.executeQuery("SELECT * FROM histories WHERE tournament_id = ? AND stamp_id = ?", withArgs:[tournament_id, stamp_id])
        let dateFormatter = NSDateFormatter()
        if err != nil {
            println("error!")
        } else {
            result = self.resultDataSetup(resultSet)
        }
        return result
    }
    
    func resultDataSetup(resultSet:[SwiftData.SDRow]) -> NSMutableArray {
        var result = NSMutableArray()
        
        for row in resultSet {
            if let id = row["ID"]?.asInt() {
                let tournament_id = row["tournament_id"]?.asInt()!
                let stamp_id      = row["stamp_id"]?.asInt()!
                let proximity     = row["proximity"]?.asInt()!
                let created_at    = row["created_at"]?.asString()!
                let updated_at    = row["updated_at"]?.asString()!
                
                let dic = ["ID":id, "tournament_id": tournament_id!, "stamp_id": stamp_id!, "proximity": proximity!, "created_at": created_at!, "updated_at": updated_at!]
                result.addObject(dic)
            }
        }
        
        return result
    }
}