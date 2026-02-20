//
//  milstoApp.swift
//  milsto
//
//  Created by Salih Bora Ozturk on 19.02.26.
//

import SwiftUI
import SwiftData

@main
struct milstoApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Milestone.self,
            Config.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            let context = container.mainContext
            if try context.fetchCount(FetchDescriptor<Config>()) == 0 {
                context.insert(Config())
            }
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
