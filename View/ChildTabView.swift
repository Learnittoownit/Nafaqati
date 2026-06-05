import SwiftUI
import Supabase

struct ChildTabView: View {
    @State private var selectedTab  = 0
    @State private var goals:       [Goal]              = []
    @State private var activity:    [ChildActivityItem] = []
    @State private var showConfetti = false
    @State private var pollTimer:   Timer?              = nil

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {

                ChildHomeView(goals: $goals, activity: $activity)
                    .tabItem {
                        Image(systemName: selectedTab == 0 ? "house.fill" : "house")
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
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation { showConfetti = false }
                        }
                    })
                    .tabItem {
                        Image(systemName: "target")
                        Text("Goals")
                    }
                    .tag(2)
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
            pollTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
                Task { await loadData() }
            }
        }
        .onDisappear {
            pollTimer?.invalidate()
            pollTimer = nil
        }
        .onChange(of: goals)    { _, _ in Task { await saveGoals() } }
        .onChange(of: activity) { _, _ in saveActivityLocally() }
    }

    func saveGoals() async {
        if let encoded = try? JSONEncoder().encode(goals) {
            UserDefaults.standard.set(encoded, forKey: "savedGoals")
        }
    }

    func saveActivityLocally() {
        if let encoded = try? JSONEncoder().encode(activity) {
            UserDefaults.standard.set(encoded, forKey: "savedChildActivity")
        }
    }

    func loadData() async {
        guard let childIdStr = UserDefaults.standard.string(forKey: "childId"),
              let childId    = UUID(uuidString: childIdStr)
        else { return }

        do {
            let fetchedGoals: [Goal] = try await supabase
                .from("goals").select()
                .eq("child_id", value: childId.uuidString)
                .neq("status", value: "deleted")
                .execute().value

            // Merge: keep locally deleted goals, add fresh ones from server
            await MainActor.run {
                let deletedGoals = goals.filter { $0.status == "deleted" }
                goals = fetchedGoals + deletedGoals
            }
        } catch {
            if let data    = UserDefaults.standard.data(forKey: "savedGoals"),
               let decoded = try? JSONDecoder().decode([Goal].self, from: data) {
                goals = decoded
            }
        }

        if let data    = UserDefaults.standard.data(forKey: "savedChildActivity"),
           let decoded = try? JSONDecoder().decode([ChildActivityItem].self, from: data) {
            activity = decoded
        }
    }
}

