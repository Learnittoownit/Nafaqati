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
    @State private var activeSheet:  GoalSheet?
    @State private var showHistory = false
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

                            await notifyParent(
                                title: "Your child set a new goal: \(newGoal.name)",
                                meta:  "Goal · \(Int(newGoal.target)) SAR")

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

                                await notifyParent(
                                    title: "Your child edited a goal: \(editedGoal.name)",
                                    meta:  "Goal edited")
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
                $0.status != "rejected"
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
            $0.status == "rejected"
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
            Text("Rejected")
                .font(.system(
                    size: 11,
                    weight: .semibold,
                    design: .rounded))
                .foregroundColor(Color(hex: "C62828"))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(hex: "FFEBEE"))
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
                    Text("\(Int(goal.saved)) SAR")
                        .font(.system(
                            size: 22,
                            weight: .bold,
                            design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(goal.percent)%")
                        .font(.system(
                            size: 22,
                            weight: .bold,
                            design: .rounded))
                        .foregroundColor(.white)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 10)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: "5B9BD5"))
                            .frame(
                                width: geo.size.width
                                * goal.progress,
                                height: 10)
                    }
                }
                .frame(height: 10)

                HStack {
                    Text("saved: \(Int(goal.saved))")
                        .font(.system(
                            size: 12,
                            design: .rounded))
                        .foregroundColor(.white.opacity(0.65))
                    Spacer()
                    Text("\(Int(goal.target - goal.saved)) SAR to go!")
                        .font(.system(
                            size: 12,
                            design: .rounded))
                        .foregroundColor(.white.opacity(0.65))
                }

                MilestoneDots(progress: goal.progress)

                Button {
                    withAnimation {
                        let item = ChildActivityItem(
                            name:     "Deleted goal: \(goal.name)",
                            amount:   0,
                            jarColor: "red",
                            sfSymbol: "trash")
                        activity.insert(item, at: 0)

                        Task {
                            try? await supabase
                                .from("goals")
                                .delete()
                                .eq("id",
                                    value: goal.id
                                        .uuidString)
                                .execute()

                            await logChildActivity(
                                title:    "Deleted goal: \(goal.name)",
                                sfSymbol: "trash",
                                jarColor: "red")

                            await notifyParent(
                                title: "Your child deleted a goal: \(goal.name)",
                                meta:  "Goal deleted")
                        }

                        if let i = goals.firstIndex(
                            where: { $0.id == goal.id }) {
                            goals.remove(at: i)
                        }
                    }
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

                                await notifyParent(
                                    title: "Your child re-requested a goal: \(goal.name)",
                                    meta:  "Goal · \(Int(goal.target)) SAR")

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
        }

        try? await supabase
            .from("child_activity")
            .insert(ChildActivityInsert(
                child_id:  childIdStr,
                title:     title,
                meta:      "",
                sf_symbol: sfSymbol,
                jar_color: jarColor))
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
