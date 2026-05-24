//
//  Item.swift
//  VaptVupt
//
//  Created by Leandro Henrique Cavalcanti Bernardes on 24/05/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
