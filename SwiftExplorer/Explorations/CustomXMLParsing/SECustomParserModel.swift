//
//  DRFeedEntity.swift
//  DailyRadio
//
//  Created by Kenny Leung on 8/22/20.
//

import Foundation
import CoreData

// Sat, 15 Aug 2020 03:00:00 +0000
private let dateFormatter:DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "E, dd MMM yyyy HH:mm:ss Z"
    return f;
}()
// Wed, 07 Oct 2020 14:15:08 PDT
private let dateFormatter2:DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "E, dd MMM yyyy HH:mm:ss zzz"
    return f;
}()

public protocol SECustomParserModel {
    var tag:String {get}
    mutating func setValue(_ value:String, forTag tag:String)
    mutating func setData(_ data:Data, forTag tag:String)
    mutating func setValue(_ value:String, forTag tag:String?, attribute:String)
    func makeChildEntity(forTag tag:String) -> SECustomParserModel?
    mutating func setChildEntity(_ value:SECustomParserModel, forTag tag:String);
}

public extension SECustomParserModel {
        
    func coerceDate(_ dateString:String?) -> Date? {
        if let dateString = dateString {
            let trimmed = dateString.trimmingCharacters(in:NSCharacterSet.whitespacesAndNewlines);
            if !trimmed.isEmpty {
                var date = dateFormatter.date(from:trimmed)
                if date == nil {
                    date = dateFormatter2.date(from:trimmed)
                }
                if date == nil {
                    print("Could not coerce date: " + dateString)
                }
                return date
            }
        }
        return nil
    }

    func coerceURL(_ urlString:String?) -> URL? {
        if let urlString = urlString {
            let trimmed = urlString.trimmingCharacters(in:NSCharacterSet.whitespacesAndNewlines)
            if !trimmed.isEmpty {
                let url = URL(string:trimmed)
                if url == nil {
                    print("Could not coerce URL: " + urlString)
                }
                return url
            }
        }
        return nil
    }

    func coerceBool(_ boolString:String?) -> Bool {
        if let boolString = boolString {
            if boolString.lowercased() == "true" {
                return true
            }
        }
        return false
    }
    
    func coerceInt32(_ intString:String?) -> Int32? {
        if let intString = intString {
            return Int32(intString)
        }
        return nil
    }
    
}
