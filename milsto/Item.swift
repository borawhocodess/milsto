//
//  Item.swift
//  milsto
//
//  Created by Salih Bora Ozturk on 19.02.26.
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
