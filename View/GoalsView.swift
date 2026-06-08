import SwiftUI
import Supabase

enum GoalSheet: Identifiable {
    case setNew
    case edit(Goal)

    var id: String {
        switch self {
        case .setNew:      return "setNew"
        case .edit(let g): return "edit_\(g.id)"
        }
    }
}

struct GoalsView: View {

    @Binding var goals:    [Goal]
    @Binding var activity: [ChildActivityItem]
    var onGoalAdded:       () -> Void
    @State private var activeSheet:      GoalSheet?
    @State private var showHistory     = false
    @State private var goalToDelete:   Goal? = nil
    @State private var showDeleteAlert = false
    let maxGoals = 5

    let goalIdeas: [(String, String)] = [
        ("📚", "Books"),
        ("🚲", "Bike"),
        ("✈️", "Trip"),
        ("🎧", "AirPods"),
    ]

    var body: some View {
        ZStack {
            Color(hex: "EEF2F8").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // ── Toggle ────────────────────
                    HStack(spacing: 0) {
                        Button {
                            showHistory = false
                        } label: {
                            Text("Active")
                                .font(.system(
                                    size: 14,
                                    weight: showHistory
                                    ? .regular : .bold,
                                    design: .rounded))
                                .foregroundColor(
                                    showHistory
                                    ? Color(hex: "8A9BB0")
                                    : Color(hex: "185FA5"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                                .background(
                                    showHistory
                                    ? Color.white
                                    : Color(hex: "EBF4FF"))
                                .cornerRadius(10)
                        }

                        Button {
                            showHistory = true
                        } label: {
                            Text("History")
                                .font(.system(
                                    size: 14,
                                    weight: showHistory
                                    ? .bold : .regular,
                                    design: .rounded))
                                .foregroundColor(
                                    showHistory
                                    ? Color(hex: "185FA5")
                                    : Color(hex: "8A9BB0"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 38)
                                .background(
                                    showHistory
                                    ? Color(hex: "EBF4FF")
                                    : Color.white)
                                .cornerRadius(10)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    if showHistory {
                        historySection
                    } else {
                        activeSection
                    }
                }
            }
        }
        .overlay {
            if showDeleteAlert, let goal = goalToDelete {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showDeleteAlert = false
                            goalToDelete    = nil
                        }

                    VStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "FFEBEE"))
                                .frame(width: 56, height: 56)
                            Image(systemName: "trash.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color(hex: "E05555"))
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 12)

                        Text("Delete \"\(goal.name)\"?")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "1B3A6B"))
                            .padding(.horizontal, 20)

                        Text("This goal will move to your History.")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(Color(hex: "8A9BB0"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.top, 6)
                            .padding(.bottom, 20)

                        Divider()

                        Button {
                            withAnimation {
                                activity.insert(ChildActivityItem(
                                    name: "Deleted goal: \(goal.name)",
                                    amount: 0, jarColor: "red", sfSymbol: "trash"), at: 0)
                                if let i = goals.firstIndex(where: { $0.id == goal.id }) {
                                    goals[i].status = "deleted"
                                }
                                Task {
                                    do {
                                        try await supabase.from("goals")
                                            .update(["status": "deleted"])
                                            .eq("id", value: goal.id.uuidString).execute()
                                        print("✅ Goal deleted in Supabase")
                                    } catch {
                                        print("❌ Failed to delete goal in Supabase: \(error)")
                                    }
                                    await logChildActivity(title: "Deleted goal: \(goal.name)", sfSymbol: "trash", jarColor: "red")
                                    let cn = UserDefaults.standard.string(forKey: "childName") ?? "Your child"
                                    await notifyParent(title: "🗑️ \(cn) deleted goal: \(goal.name)", meta: "Goal deleted · Target was \(Int(goal.target)) SAR")
                                }
                            }
                            showDeleteAlert = false
                            goalToDelete    = nil
                        } label: {
                            Text("Yes, delete it")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(hex: "E05555"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                        }

                        Divider()

                        Button {
                            showDeleteAlert = false
                            goalToDelete    = nil
                        } label: {
                            Text("No, keep it")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(hex: "1B3A6B"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                        }
                        .padding(.bottom, 8)
                    }
                    .background(Color.white)
                    .cornerRadius(20)
                    .padding(.horizontal, 40)
                }
            }
        }
        .fullScreenCover(item: $activeSheet) { sheet in
            switch sheet {
            case .setNew:
                SetGoalView { newGoal in
                    guard let childIdStr = UserDefaults
                        .standard
                        .string(forKey: "childId"),
                          let childId = UUID(
                            uuidString: childIdStr)
                    else { return }

                    Task {
                        struct GoalInsert: Encodable {
                            let child_id:     String
                            let title:        String
                            let icon:         String
                            let target_price: Double
                            let saved_amount: Double
                            let days:         Int
                        }

                        do {
                            let inserted: [Goal] =
                                try await supabase
                                .from("goals")
                                .insert(GoalInsert(
                                    child_id:
                                        childId.uuidString,
                                    title:
                                        newGoal.name,
                                    icon:
                                        newGoal.icon,
                                    target_price:
                                        newGoal.target,
                                    saved_amount: 0,
                                    days:
                                        newGoal.days))
                                .select()
                                .execute()
                                .value

                            await MainActor.run {
                                if let saved =
                                    inserted.first {
                                    goals.append(saved)
                                } else {
                                    goals.append(newGoal)
                                }
                                let item = ChildActivityItem(
                                    name:     "New goal: \(newGoal.name)",
                                    amount:   0,
                                    jarColor: "blue",
                                    sfSymbol: "target")
                                activity.insert(item, at: 0)
                                onGoalAdded()
                            }

                            await logChildActivity(
                                title:    "New goal: \(newGoal.name)",
                                sfSymbol: "target",
                                jarColor: "blue")

                            let cn1 = UserDefaults.standard.string(forKey: "childName") ?? "Your child"
                            await notifyParent(
                                title: "🎯 \(cn1) set a new goal: \(newGoal.name)",
                                meta:  "New goal · Target: \(Int(newGoal.target)) SAR · \(newGoal.days) days")

                        } catch {
                            print("❌ save goal: \(error)")
                            await MainActor.run {
                                goals.append(newGoal)
                                onGoalAdded()
                            }
                        }
                    }
                }

            case .edit(let goal):
                if let index = goals.firstIndex(
                    where: { $0.id == goal.id }) {
                    EditGoalView(
                        goal: $goals[index],
                        onSave: { editedGoal in
                            Task {
                                struct GoalUpdate: Encodable {
                                    let title:        String
                                    let icon:         String
                                    let target_price: Double
                                    let days:         Int
                                }
                                try? await supabase
                                    .from("goals")
                                    .update(GoalUpdate(
                                        title:
                                            editedGoal.name,
                                        icon:
                                            editedGoal.icon,
                                        target_price:
                                            editedGoal.target,
                                        days:
                                            editedGoal.days))
                                    .eq("id",
                                        value: editedGoal
                                            .id.uuidString)
                                    .execute()

                                await logChildActivity(
                                    title:    "Edited goal: \(editedGoal.name)",
                                    sfSymbol: "pencil",
                                    jarColor: "purple")

                                let cn2 = UserDefaults.standard.string(forKey: "childName") ?? "Your child"
                                await notifyParent(
                                    title: "✏️ \(cn2) edited goal: \(editedGoal.name)",
                                    meta:  "Target: \(Int(editedGoal.target)) SAR · \(editedGoal.days) days")
                            }

                            let item = ChildActivityItem(
                                name:     "Edited goal: \(editedGoal.name)",
                                amount:   0,
                                jarColor: "purple",
                                sfSymbol: "pencil")
                            activity.insert(item, at: 0)
                        })
                }
            }
        }
    }

    // ── Active goals section ──────────────
    var activeSection: some View {
        VStack(spacing: 20) {
            let activeGoals = goals.filter {
                $0.status != "rejected" && $0.status != "deleted" && $0.status != "achieved"
            }

            if activeGoals.isEmpty {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "E8EDF5"))
                            .frame(width: 64, height: 64)
                        Image(systemName: "target")
                            .font(.system(
                                size: 28,
                                weight: .medium))
                            .foregroundColor(
                                Color(hex: "185FA5"))
                    }
                    Text("No goal yet")
                        .font(.system(
                            size: 16,
                            weight: .semibold,
                            design: .rounded))
                        .foregroundColor(Color(hex: "1B3A6B"))
                    Text("Set a goal and start saving\ntoward something you love!")
                        .font(.system(
                            size: 13,
                            design: .rounded))
                        .foregroundColor(Color(hex: "8A9BB0"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.white)
                .cornerRadius(20)
                .padding(.horizontal, 20)

            } else {
                let visibleGoals = Array(
                    activeGoals.prefix(maxGoals))
                let hiddenCount =
                    activeGoals.count - visibleGoals.count

                ForEach(
                    Array(visibleGoals.enumerated()),
                    id: \.element.id
                ) { index, goal in
                    goalCard(goal: goal, index: index)
                }

                if hiddenCount > 0 {
                    HStack(spacing: 10) {
                        Image(systemName: "archivebox.fill")
                            .foregroundColor(
                                Color(hex: "185FA5"))
                            .font(.system(size: 16))
                        VStack(alignment: .leading,
                               spacing: 2) {
                            Text("\(hiddenCount) more goal\(hiddenCount > 1 ? "s" : "") waiting")
                                .font(.system(
                                    size: 14,
                                    weight: .semibold,
                                    design: .rounded))
                                .foregroundColor(
                                    Color(hex: "1B3A6B"))
                            Text("Delete a goal above to see the next one")
                                .font(.system(
                                    size: 12,
                                    design: .rounded))
                                .foregroundColor(
                                    Color(hex: "8A9BB0"))
                        }
                        Spacer()
                        Text("\(activeGoals.count) total")
                            .font(.system(
                                size: 12,
                                weight: .semibold,
                                design: .rounded))
                            .foregroundColor(
                                Color(hex: "185FA5"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(hex: "EBF4FF"))
                            .cornerRadius(10)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                }
            }

            // Goal ideas
            VStack(alignment: .leading, spacing: 14) {
                Text("NEXT GOAL IDEAS")
                    .font(.system(
                        size: 12,
                        weight: .semibold,
                        design: .rounded))
                    .foregroundColor(Color(hex: "8A9BB0"))
                    .tracking(1.2)
                    .padding(.horizontal, 20)

                ScrollView(.horizontal,
                           showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(goalIdeas,
                                id: \.1) { idea in
                            Button {
                                activeSheet = .setNew
                            } label: {
                                VStack(spacing: 8) {
                                    Text(idea.0)
                                        .font(.system(
                                            size: 32))
                                    Text(idea.1)
                                        .font(.system(
                                            size: 12,
                                            design: .rounded))
                                        .foregroundColor(
                                            Color(hex: "1B3A6B"))
                                }
                                .frame(width: 88, height: 88)
                                .background(
                                    Color(hex: "E0E6EF"))
                                .cornerRadius(18)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }

            Button {
                activeSheet = .setNew
            } label: {
                Text("+ Set New Goal")
                    .font(.system(
                        size: 16,
                        weight: .semibold,
                        design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color(hex: "185FA5"))
                    .cornerRadius(27)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }

    // ── History section ───────────────────
    var historySection: some View {
        let historyGoals = goals.filter {
            $0.status == "rejected" || $0.status == "deleted" || $0.status == "achieved"
        }

        return VStack(spacing: 12) {
            if historyGoals.isEmpty {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "E8EDF5"))
                            .frame(width: 64, height: 64)
                        Image(systemName:
                            "clock.arrow.circlepath")
                            .font(.system(size: 28))
                            .foregroundColor(
                                Color(hex: "185FA5"))
                    }
                    Text("No history yet")
                        .font(.system(
                            size: 16,
                            weight: .semibold,
                            design: .rounded))
                        .foregroundColor(Color(hex: "1B3A6B"))
                    Text("Rejected goals\nwill appear here")
                        .font(.system(
                            size: 13,
                            design: .rounded))
                        .foregroundColor(Color(hex: "8A9BB0"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.white)
                .cornerRadius(20)
                .padding(.horizontal, 20)
            } else {
                ForEach(historyGoals) { goal in
                    historyCard(goal: goal)
                }
            }
        }
        .padding(.bottom, 32)
    }

    // ── History card ──────────────────────
    func historyCard(goal: Goal) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "FFEBEE"))
                    .frame(width: 52, height: 52)
                GoalIconView(icon: goal.icon, size: 26)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.name)
                    .font(.system(
                        size: 15,
                        weight: .semibold,
                        design: .rounded))
                    .foregroundColor(Color(hex: "1B3A6B"))
                Text("Target: \(Int(goal.target)) SAR")
                    .font(.system(
                        size: 12,
                        design: .rounded))
                    .foregroundColor(Color(hex: "8A9BB0"))
            }
            Spacer()
            Text(goal.status == "achieved"
                 ? "🏆 Achieved"
                 : goal.status == "deleted"
                   ? "Deleted"
                   : "Rejected")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(goal.status == "achieved" ? Color(hex: "B8860B") : goal.status == "deleted" ? Color(hex: "555555") : Color(hex: "C62828"))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(goal.status == "achieved" ? Color(hex: "FFF8DC") : goal.status == "deleted" ? Color(hex: "EEEEEE") : Color(hex: "FFEBEE"))
                .cornerRadius(10)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }

    // ── Goal card ─────────────────────────
    func goalCard(goal: Goal, index: Int) -> some View {
        ZStack {
            VStack(alignment: .leading, spacing: 14) {

                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white)
                            .frame(width: 60, height: 60)
                        GoalIconView(icon: goal.icon,
                                     size: 32)
                    }
                    VStack(alignment: .leading,
                           spacing: 3) {
                        Text(goal.name)
                            .font(.system(
                                size: 18,
                                weight: .bold,
                                design: .rounded))
                            .foregroundColor(.white)
                        Text("goal: \(Int(goal.target)) SAR")
                            .font(.system(
                                size: 13,
                                design: .rounded))
                            .foregroundColor(
                                .white.opacity(0.65))
                    }
                    Spacer()
                    if goal.status == "approved" {
                        Button {
                            activeSheet = .edit(goal)
                        } label: {
                            Image(systemName:
                                "pencil.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(
                                    .white.opacity(0.8))
                        }
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Int(goal.saved)) SAR")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("from saving jar")
                            .font(.system(size: 10, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                    Text("\(goal.percent)%")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(goal.isAchieved ? Color(hex: "FAC775") : .white)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 10)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(goal.isAchieved ? Color(hex: "FAC775") : Color(hex: "5B9BD5"))
                            .frame(
                                width: geo.size.width * goal.progress,
                                height: 10)
                    }
                }
                .frame(height: 10)

                // ── Achievement button when goal is reached
                if goal.isAchieved {
                    Button {
                        Task { await claimGoal(goal) }
                    } label: {
                        HStack(spacing: 8) {
                            Text("🎉")
                                .font(.system(size: 20))
                            Text("I achieved my goal! Claim it!")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "1B3A6B"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "FAC775"))
                        .cornerRadius(14)
                    }
                    .padding(.top, 4)
                } else {
                    HStack {
                        Text("💰 \(Int(goal.saved)) SAR saved")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))
                        Spacer()
                        Text("\(Int(goal.target - goal.saved)) SAR to go!")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.white.opacity(0.75))
                    }
                }

                MilestoneDots(progress: goal.progress)

                Button {
                    goalToDelete   = goal
                    showDeleteAlert = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 13))
                        Text("Delete goal")
                            .font(.system(
                                size: 13,
                                weight: .medium,
                                design: .rounded))
                    }
                    .foregroundColor(Color(hex: "E05555"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(10)
                }
            }
            .padding(20)
            .background(
                goal.status == "rejected"
                ? Color(hex: "8B1A1A")
                : Color(hex: "1B3A6B"))
            .cornerRadius(20)
            .padding(.horizontal, 20)

            // ── Pending overlay ───────────
            if goal.status == "pending" {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.55))
                    .padding(.horizontal, 20)

                VStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                    Text("Waiting for parent approval")
                        .font(.system(
                            size: 15,
                            weight: .semibold,
                            design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Text("Your parent needs to approve\nthis goal before you can start saving")
                        .font(.system(
                            size: 12,
                            design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
            }

            // ── Rejected overlay ──────────
            if goal.status == "rejected" {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.red.opacity(0.3))
                    .padding(.horizontal, 20)

                VStack(spacing: 12) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: "FF6B6B"))
                    Text("Goal rejected")
                        .font(.system(
                            size: 15,
                            weight: .semibold,
                            design: .rounded))
                        .foregroundColor(.white)
                    Text("Your parent did not approve this goal.")
                        .font(.system(
                            size: 12,
                            design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)

                    HStack(spacing: 12) {
                        Button {
                            Task {
                                try? await supabase
                                    .from("goals")
                                    .update(["status":
                                                "pending"])
                                    .eq("id",
                                        value: goal.id
                                            .uuidString)
                                    .execute()

                                await logChildActivity(
                                    title:    "Re-requested goal: \(goal.name)",
                                    sfSymbol: "arrow.clockwise",
                                    jarColor: "blue")

                                let cn4 = UserDefaults.standard.string(forKey: "childName") ?? "Your child"
                                await notifyParent(
                                    title: "🔄 \(cn4) re-requested goal: \(goal.name)",
                                    meta:  "Goal · Target: \(Int(goal.target)) SAR")

                                if let i = goals.firstIndex(
                                    where: {
                                        $0.id == goal.id
                                    }) {
                                    await MainActor.run {
                                        goals[i].status =
                                            "pending"
                                    }
                                }
                            }
                        } label: {
                            Text("Send again")
                                .font(.system(
                                    size: 13,
                                    weight: .semibold,
                                    design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(
                                    Color(hex: "185FA5"))
                                .cornerRadius(10)
                        }

                        Button {
                            withAnimation {
                                Task {
                                    try? await supabase
                                        .from("goals")
                                        .delete()
                                        .eq("id",
                                            value: goal.id
                                                .uuidString)
                                        .execute()
                                }
                                if let i = goals.firstIndex(
                                    where: {
                                        $0.id == goal.id
                                    }) {
                                    goals.remove(at: i)
                                }
                            }
                        } label: {
                            Text("Delete")
                                .font(.system(
                                    size: 13,
                                    weight: .semibold,
                                    design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(
                                    Color(hex: "E05555"))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, 40)
            }
        }
    }

    // ── Child claims achieved goal ──────────
    func claimGoal(_ goal: Goal) async {
        guard let childIdStr  = UserDefaults.standard.string(forKey: "childId"),
              let parentIdStr = UserDefaults.standard.string(forKey: "parentId"),
              let childId     = UUID(uuidString: childIdStr)
        else { return }

        // 1. Mark goal as "achieved" status in Supabase
        struct GoalUpdate: Encodable { let status: String; let is_achieved: Bool }
        try? await supabase.from("goals")
            .update(GoalUpdate(status: "achieved", is_achieved: true))
            .eq("id", value: goal.id.uuidString)
            .execute()

        // 2. Deduct target amount from saving jar
        if let jars = try? await supabase.from("jars").select()
            .eq("child_id", value: childId.uuidString)
            .eq("type", value: "saving")
            .execute().value as [Jar],
           let jar = jars.first {
            let newBalance = max(0, jar.balance - goal.target)
            try? await supabase.from("jars")
                .update(["balance": newBalance])
                .eq("id", value: jar.id.uuidString)
                .execute()
        }

        // 3. Log to child activity
        await logChildActivity(
            title:    "🏆 Goal achieved: \(goal.name)!",
            sfSymbol: "star.fill",
            jarColor: "yellow")

        // 4. Notify parent
        let cn = UserDefaults.standard.string(forKey: "childName") ?? "Your child"
        struct PAI: Encodable { let parent_id: String; let title: String; let meta: String }
        try? await supabase.from("parent_activity")
            .insert(PAI(parent_id: parentIdStr,
                        title: "🏆 \(cn) achieved their goal: \(goal.name)!",
                        meta: "Goal achieved · \(Int(goal.target)) SAR"))
            .execute()

        // 5. Update local state — move to history and fire confetti
        await MainActor.run {
            if let idx = goals.firstIndex(where: { $0.id == goal.id }) {
                goals[idx].status     = "achieved"
                goals[idx].isAchieved = true
            }
            onGoalAdded() // triggers confetti in ChildTabView
        }
    }

    // ── Log child activity to Supabase ────
    func logChildActivity(title: String,
                          sfSymbol: String,
                          jarColor: String) async {
        guard let childIdStr = UserDefaults.standard
            .string(forKey: "childId")
        else { return }

        struct ChildActivityInsert: Encodable {
            let child_id:  String
            let title:     String
            let meta:      String
            let sf_symbol: String
            let jar_color: String
            let amount:    Double
        }

        try? await supabase
            .from("child_activity")
            .insert(ChildActivityInsert(
                child_id:  childIdStr,
                title:     title,
                meta:      "",
                sf_symbol: sfSymbol,
                jar_color: jarColor,
                amount:    0))
            .execute()
    }

    // ── Notify parent in Supabase ─────────
    func notifyParent(title: String,
                      meta: String) async {
        guard let parentIdStr = UserDefaults.standard
            .string(forKey: "parentId"),
              let parentId = UUID(
                uuidString: parentIdStr)
        else {
            print("❌ notifyParent: no parentId")
            return
        }

        struct ActivityInsert: Encodable {
            let parent_id: String
            let title:     String
            let meta:      String
        }

        do {
            try await supabase
                .from("parent_activity")
                .insert(ActivityInsert(
                    parent_id: parentId.uuidString,
                    title:     title,
                    meta:      meta))
                .execute()
            print("✅ notifyParent: \(title)")
        } catch {
            print("❌ notifyParent error: \(error)")
        }
    }
}

// ── Milestone dots ───────────────────────
struct MilestoneDots: View {
    let progress: Double
    let milestones = ["Start", "50%", "75%", "Done!"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(milestones.enumerated()),
                    id: \.offset) { i, milestone in
                VStack(spacing: 6) {
                    Circle()
                        .fill(dotColor(index: i))
                        .frame(width: 18, height: 18)
                    Text(milestone)
                        .font(.system(
                            size: 10,
                            design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                if i < milestones.count - 1 {
                    Rectangle()
                        .fill(lineColor(index: i))
                        .frame(height: 3)
                        .padding(.bottom, 20)
                }
            }
        }
    }

    func dotColor(index: Int) -> Color {
        let thresholds: [Double] = [0.0, 0.5, 0.75, 1.0]
        guard progress >= thresholds[index] else {
            return Color.white.opacity(0.3)
        }
        if index == 1 && progress >= 0.5
            && progress < 0.75 {
            return Color(hex: "F5C842")
        }
        if index == 2 && progress >= 0.75
            && progress < 1.0 {
            return Color(hex: "F5C842")
        }
        if index == 3 && progress >= 1.0 {
            return Color(hex: "F5C842")
        }
        return Color(hex: "4CAF50")
    }

    func lineColor(index: Int) -> Color {
        let thresholds: [Double] = [0.0, 0.5, 0.75]
        return progress > thresholds[index]
            ? Color(hex: "4CAF50")
            : Color.white.opacity(0.2)
    }
}

// ─────────────────────────────────────────────
// MARK: - Preview
// ─────────────────────────────────────────────

#Preview {
    GoalsView(
        goals: .constant([
            Goal(name: "Bike", icon: "🚲", target: 200, saved: 50, days: 30),
            Goal(name: "PlayStation", icon: "🎮", target: 500, saved: 0, days: 60, status: "rejected"),
            Goal(name: "AirPods", icon: "🎧", target: 300, saved: 0, days: 30, status: "deleted")
        ]),
        activity: .constant([]),
        onGoalAdded: {}
    )
}
