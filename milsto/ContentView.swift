//
//  ContentView.swift
//  milsto
//
//  Created by Salih Bora Ozturk on 19.02.26.
//

import SwiftUI
import SwiftData


@Model
final class Item {
    var timestamp: Date

    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}


struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
        Text("hello world")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
