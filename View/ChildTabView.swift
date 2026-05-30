import SwiftUI
import Supabase

struct ChildTabView: View {
    @State private var selectedTab  = 0
    @State private var goals:       [Goal]              = []
    @State private var activity:    [ChildActivityItem] = []
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                ChildHomeView(
                    goals:    $goals,
                    activity: $activity)
                    .tabItem {
                        Image(systemName: selectedTab == 0
                              ? "house.fill" : "house")
                        Text("Home")
                    }
                    .tag(0)

                JarsView()
                    .tabItem {
                        Image(systemName: "bag")
                        Text("Jars")
                    }
                    .tag(1)

                GoalsView(
                    goals:    $goals,
                    activity: $activity,
                    onGoalAdded: {
                        withAnimation { showConfetti = true }
                        DispatchQueue.main.asyncAfter(
                            deadline: .now() + 3) {
                            withAnimation { showConfetti = false }
                        }
                    })
                    .tabItem {
                        Image(systemName: "target")
                        Text("Goals")
                    }
                    .tag(2)

                ChildSettingsView()
                    .tabItem {
                        Image(systemName: "gearshape")
                        Text("Settings")
                    }
                    .tag(3)
            }
            .tint(Color(hex: "1B3A6B"))

            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            Task { await loadData() }
            // Poll every 10 seconds to check
            // if parent approved/rejected goals
            Timer.scheduledTimer(
                withTimeInterval: 10,
                repeats: true) { _ in
                Task { await loadData() }
            }
        }        .onChange(of: goals) { _, _ in
            Task { await saveGoals() }
        }
        .onChange(of: activity) { _, _ in
            saveActivityLocally()
        }
    }

    // ── Save goals to Supabase ────────────
    func saveGoals() async {
        guard let childIdStr = UserDefaults.standard
            .string(forKey: "childId"),
              let childId = UUID(uuidString: childIdStr)
        else { return }

        // Also save locally as backup
        if let encoded = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(
                encoded, forKey: "savedGoals")
        }
    }

    func saveActivityLocally() {
        if let encoded = try? JSONEncoder().encode(activity) {
            UserDefaults.standard.set(
                encoded, forKey: "savedChildActivity")
        }
    }

    // ── Load data from Supabase ───────────
    func loadData() async {
        guard let childIdStr = UserDefaults.standard
            .string(forKey: "childId"),
              let childId = UUID(uuidString: childIdStr)
        else { return }

        do {
            // Load goals from Supabase
            let fetchedGoals: [Goal] = try await supabase
                .from("goals")
                .select()
                .eq("child_id", value: childId.uuidString)
                .execute()
                .value

            await MainActor.run {
                goals = fetchedGoals
            }

        } catch {
            print("❌ loadGoals from Supabase: \(error)")
            // Fallback to local storage
            if let data = UserDefaults.standard.data(
                forKey: "savedGoals"),
               let decoded = try? JSONDecoder().decode(
                [Goal].self, from: data) {
                goals = decoded
            }
        }

        // Load activity from local storage
        if let data = UserDefaults.standard.data(
            forKey: "savedChildActivity"),
           let decoded = try? JSONDecoder().decode(
            [ChildActivityItem].self, from: data) {
            activity = decoded
        }
    }
}
