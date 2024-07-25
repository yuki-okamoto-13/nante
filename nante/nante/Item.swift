//
//  Item.swift
//  nante
//
//  Created by okamoto yuki on 2024/07/25.
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
