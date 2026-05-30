import SwiftUI
import Combine
import Supabase

// ─────────────────────────────────────────────
// MARK: - Activity Item (Parent side)
// ─────────────────────────────────────────────
struct ActivityItem: Identifiable {
    let id = UUID()
    let title: String
    let meta: String
    let isToday: Bool
}

// ─────────────────────────────────────────────
// MARK: - Allowance Schedule
// ─────────────────────────────────────────────
struct AllowanceSchedule {
    let childName: String
    let nextDueDate: Date
}

// ─────────────────────────────────────────────
// MARK: - ParentViewModel
// ─────────────────────────────────────────────
@MainActor
final class ParentViewModel: ObservableObject {

    @Published var parentName: String  = ""
    @Published var balance: Double     = 0
    @Published var activeChildren: Int = 0
    @Published var moneySent: Double   = 0
    @Published var activeGoals: Int    = 0
    @Published var activity: [ActivityItem]      = []
    @Published var allowanceSchedule: AllowanceSchedule? = nil

    var parentId: UUID? = nil

    var reminderText: String? {
        guard let schedule = allowanceSchedule else {
            return nil
        }
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(
                for: schedule.nextDueDate)
        ).day ?? 999

        switch days {
        case 0:  return "\(schedule.childName)'s allowance is due today!"
        case 1:  return "\(schedule.childName)'s allowance is due tomorrow"
        case 2:  return "\(schedule.childName)'s allowance is due in 2 days"
        default: return nil
        }
    }

    // ── Load all parent data from Supabase ──
    func loadFromSupabase(parentId: UUID) async {
        self.parentId = parentId

        do {
            let children: [ChildProfile] = try await supabase
                .from("child_profile")
                .select()
                .eq("parent_id", value: parentId.uuidString)
                .execute()
                .value

            let acts: [ParentActivityRow] = try await supabase
                .from("parent_activity")
                .select()
                .eq("parent_id", value: parentId.uuidString)
                .order("created_at", ascending: false)
                .limit(20)
                .execute()
                .value

            let activityItems = acts.map { row in
                ActivityItem(
                    title:   row.title,
                    meta:    row.meta ?? "",
                    isToday: Calendar.current
                        .isDateInToday(
                            row.createdAt ?? Date()))
            }

            await MainActor.run {
                self.activeChildren = children.count
                self.activity       = activityItems
            }

        } catch {
            print("❌ loadFromSupabase: \(error)")
        }
    }

    // ── Log activity to Supabase ───────────
    func logActivity(title: String,
                     meta: String) async {
        guard let parentId = parentId else { return }

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

            await MainActor.run {
                self.activity.insert(
                    ActivityItem(
                        title:   title,
                        meta:    meta,
                        isToday: true),
                    at: 0)
            }
        } catch {
            print("❌ logActivity: \(error)")
        }
    }

    func addToBalance(_ amount: Double) {
        balance += amount
        Task {
            await logActivity(
                title: "You added \(Int(amount)) SAR to balance",
                meta:  "Today · Just now")
        }
    }

    func sendMoney(to childName: String,
                   amount: Double,
                   type: String) {
        balance   -= amount
        moneySent += amount
        Task {
            await logActivity(
                title: "You transferred \(Int(amount)) SAR to \(childName)",
                meta:  "Today · \(type)")
        }
    }

    func setReminder(childName: String,
                     nextDueDate: Date) {
        allowanceSchedule = AllowanceSchedule(
            childName:   childName,
            nextDueDate: nextDueDate)
        Task {
            await logActivity(
                title: "You set up a reminder",
                meta:  "Today · \(childName)")
        }
    }
}

// ── Supabase row model ────────────────────
struct ParentActivityRow: Codable, Identifiable {
    let id:        UUID
    let parentId:  UUID
    let title:     String
    let meta:      String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case parentId  = "parent_id"
        case title
        case meta
        case createdAt = "created_at"
    }
}
