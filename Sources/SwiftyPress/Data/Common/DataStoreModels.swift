//
//  DataStoreModels.swift
//  SwiftyPress
//
//  Created by Basem Emara on 2019-05-23.
//  Copyright © 2019 Zamzam Inc. All rights reserved.
//

import Foundation

public enum DataStoreModels {
    
    public struct ModifiedRequest {
        let taxonomies: [String]
        let postMetaKeys: [String]
        let limit: Int?
    }
    
    public struct CacheRequest {
        let payload: SeedPayloadType
        let lastPulledAt: Date
    }
}
