//
//  SyncActivity.swift
//  SwiftyPress
//
//  Created by Basem Emara on 2018-10-17.
//

import RealmSwift

@objcMembers
class SyncActivity: Object {
    dynamic var type: String = ""
    dynamic var lastPulledAt: Date?
    
    override static func primaryKey() -> String? {
        return "type"
    }
}
