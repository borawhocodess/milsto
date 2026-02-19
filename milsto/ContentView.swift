//
//  ContentView.swift
//  milsto
//
//  Created by Salih Bora Ozturk on 19.02.26.
//

import SwiftUI
import SwiftData

@Model
final class Milestone {
    var id: UUID = UUID()
    var createdAt: Date = Date()
    var target: Date = Date()
    var title: String = ""
    var notes: String = ""

    init(id: UUID = UUID(), createdAt: Date = Date(), target: Date = Date(), title: String, notes: String = "") {
        self.id = id
        self.createdAt = createdAt
        self.target = target
        self.title = title
        self.notes = notes
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            AddView()
                .tabItem {
                    Label("Add", systemImage: "plus")
                }

            ListView()
                .tabItem {
                    Label("List", systemImage: "list.dash")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

struct AddView: View {
    @Environment(\.modelContext) private var context

    @State private var target: Date = Date()
    @State private var title: String = ""
    @State private var notes: String = ""

    @FocusState private var focusedField: Field?

    enum Field {
        case title, notes
    }

    private var isAddButtonDisabled: Bool {
        title.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    DatePicker("Date", selection: $target, displayedComponents: [.hourAndMinute, .date])
                        .datePickerStyle(.compact)
                        .labelsHidden()

                    TextField("Title", text: $title)
                        .focused($focusedField, equals: .title)

                    TextField("Notes", text: $notes)
                        .focused($focusedField, equals: .notes)
                }
                .padding()
                .onSubmit(switchFocusField)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .textFieldStyle(.roundedBorder)

                Button("Add", action: addMilestone)
                    .buttonStyle(.borderedProminent)
                    .disabled(isAddButtonDisabled)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Milestone")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset", action: resetForm)
                }
            }
        }
    }

    private func switchFocusField() {
        switch focusedField {
        case .title:
            focusedField = .notes
        case .notes:
            focusedField = nil
        case .none:
            focusedField = nil
        }
    }

    private func addMilestone() {
        let newMilestone = Milestone(target: target, title: title, notes: notes)
        context.insert(newMilestone)
        resetForm()
    }

    private func resetForm() {
        target = target.addingTimeInterval(3 * 60)
        title = ""
        notes = ""
        focusedField = .title
    }
}

struct ListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Milestone.createdAt, order: .reverse) private var milestones: [Milestone]
    @State private var searchText = ""

    @AppStorage("showTitle") private var showTitle: Bool = true
    @AppStorage("showTarget") private var showTarget: Bool = true
    @AppStorage("showCountdown") private var showCountdown: Bool = true
    @AppStorage("showNotes") private var showNotes: Bool = true

    var filteredMilestones: [Milestone] {
        if searchText.isEmpty {
            return milestones
        } else {
            return milestones.filter { milestone in
                milestone.title.localizedCaseInsensitiveContains(searchText) ||
                milestone.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var groupedMilestones: [(key: Date, values: [Milestone])] {
        let grouped = Dictionary(grouping: filteredMilestones) {
            Calendar.current.startOfDay(for: $0.createdAt)
        }
        return grouped.map { (key: $0.key, values: $0.value) }
            .sorted { $0.key > $1.key }
    }

    var body: some View {
        NavigationStack {
            Group {
                if !filteredMilestones.isEmpty {
                    List {
                        ForEach(groupedMilestones, id: \.key) { group in
                            Section(header: Text(formattedDate(group.key))) {
                                ForEach(group.values) { milestone in
                                    NavigationLink {
                                        MilestoneDetailView(milestone: milestone)
                                    } label: {
                                        MilestoneRowView(
                                            milestone: milestone,
                                            showTitle: showTitle,
                                            showTarget: showTarget,
                                            showCountdown: showCountdown,
                                            showNotes: showNotes
                                        )
                                    }
                                }
                                .onDelete { indexSet in
                                    let itemsToDelete = indexSet.map { group.values[$0] }
                                    itemsToDelete.forEach { context.delete($0) }
                                }
                            }
                        }
                    }
                } else {
                    ContentUnavailableView("No Milestones", systemImage: "list.dash")
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Milestones")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack {
                        Button {
                            showTitle.toggle()
                        } label: {
                            Image(systemName: "t.circle")
                                .symbolVariant(showTitle ? .fill : .none)
                        }

                        Button {
                            showTarget.toggle()
                        } label: {
                            Image(systemName: "d.circle")
                                .symbolVariant(showTarget ? .fill : .none)
                        }

                        Button {
                            showCountdown.toggle()
                        } label: {
                            Image(systemName: "c.circle")
                                .symbolVariant(showCountdown ? .fill : .none)
                        }

                        Button {
                            showNotes.toggle()
                        } label: {
                            Image(systemName: "n.circle")
                                .symbolVariant(showNotes ? .fill : .none)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.formatted(.dateTime.year().month().day())
        }
    }
}

struct MilestoneRowView: View {
    let milestone: Milestone
    let showTitle: Bool
    let showTarget: Bool
    let showCountdown: Bool
    let showNotes: Bool

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            VStack(alignment: .leading) {
                if !milestone.notes.isEmpty {
                    Text(milestone.notes)
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                        .opacity(showNotes ? 1 : 0)
                }

                HStack(alignment: .firstTextBaseline) {
                    Text(milestone.title)
                        .font(.headline)
                        .opacity(showTitle ? 1 : 0)

                    Spacer()

                    Text(countdownString(to: milestone.target, now: timeline.date))
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .opacity(showCountdown ? 1 : 0)
                }

                Text(milestone.target.formatted(.dateTime.year().month().day().hour().minute()))
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .opacity(showTarget ? 1 : 0)
            }
            .padding(.trailing)
        }
    }

    private func countdownString(to target: Date, now: Date) -> String {
        let totalSeconds = max(0, Int(target.timeIntervalSince(now)))

        let days = totalSeconds / 86_400
        let hours = (totalSeconds % 86_400) / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        return String(format: "%02dd %02dh %02dm %02ds", days, hours, minutes, seconds)
    }
}

struct MilestoneDetailView: View {
    @Environment(\.dismiss) private var dismiss

    @Bindable var milestone: Milestone

    @FocusState private var focusedField: Field?

    enum Field {
        case title, notes
    }

    private var isDoneButtonDisabled: Bool {
        milestone.title.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack {
                DatePicker("Date", selection: $milestone.target, displayedComponents: [.hourAndMinute, .date])
                    .datePickerStyle(.compact)
                    .labelsHidden()

                TextField("Title", text: $milestone.title)
                    .focused($focusedField, equals: .title)

                TextField("Notes", text: $milestone.notes)
                    .focused($focusedField, equals: .notes)
            }
            .padding()
            .onSubmit(switchFocusField)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .textFieldStyle(.roundedBorder)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Edit Milestone")
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button("Done", action: dismiss.callAsFunction)
                    .disabled(isDoneButtonDisabled)
            }
        }
    }

    private func switchFocusField() {
        switch focusedField {
        case .title:
            focusedField = .notes
        case .notes:
            focusedField = nil
        case .none:
            focusedField = nil
        }
    }
}

struct SettingsView: View {
    var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "version \(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: HelpView()) {
                        Label("Help", systemImage: "lifepreserver")
                    }
                }

                Section {
                    HStack {
                        Spacer()
                        Text("milsto by sbo")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                } footer: {
                    HStack {
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.tertiary)
                            .padding(.bottom)
                            .padding(.bottom)
                            .padding(.bottom)
                        Spacer()
                    }
                }
                .listRowBackground(Color.accentColor.opacity(0))
            }
            .navigationTitle("Settings")
        }
    }
}

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• Need help?")
                        Text("• Found a bug?")
                        Text("• Have a question?")
                        Text("• Have ideas or feedback?")
                    }
                    .padding(.vertical)

                    HStack {
                        Text("Email to")
                        Text("boraozturksalih@gmail.com")
                        Spacer()
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Help & Support")
    }
}

#Preview("list") {
    ListView()
        .modelContainer(SampleData.shared.modelContainer)
}

#Preview("settings") {
    SettingsView()
        .modelContainer(SampleData.shared.modelContainer)
}

#Preview("help") {
    NavigationStack {
        HelpView()
            .modelContainer(SampleData.shared.modelContainer)
    }
}

#Preview("content") {
    ContentView()
        .modelContainer(SampleData.shared.modelContainer)
}

@MainActor
class SampleData {
    static let shared = SampleData()

    let modelContainer: ModelContainer

    var context: ModelContext {
        modelContainer.mainContext
    }

    private init() {
        let schema = Schema([Milestone.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            insertSampleData()
            try context.save()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    private func insertSampleData() {
        for milestone in Milestone.sampleData {
            context.insert(milestone)
        }
    }
}

extension Milestone {
    static let sampleData = [
        Milestone(createdAt: Date(), target: Date().addingTimeInterval(3600), title: "Leave for airport", notes: "Passport + ticket"),
        Milestone(createdAt: Date(), target: Date().addingTimeInterval(7200), title: "Project deadline", notes: "Submit final report"),
        Milestone(createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, target: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, title: "Gym", notes: "Leg day"),
        Milestone(createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, target: Calendar.current.date(byAdding: .day, value: 2, to: Date())!, title: "Pay rent"),
        Milestone(createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, target: Calendar.current.date(byAdding: .day, value: 7, to: Date())!, title: "Weekend trip", notes: "Pack light")
    ]
}
