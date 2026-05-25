import SwiftUI
import Combine

// ─────────────────────────────────────────────
// MARK: - Activity Item
// ─────────────────────────────────────────────
struct ActivityItem: Identifiable {
    let id = UUID()
    let title: String
    let meta: String
    let isToday: Bool       // true = blue dot, shown by default
}

// ─────────────────────────────────────────────
// MARK: - Allowance Schedule (for reminder)
// ─────────────────────────────────────────────
struct AllowanceSchedule {
    let childName: String
    let nextDueDate: Date   // set by parent when scheduling
}

// ─────────────────────────────────────────────
// MARK: - ParentViewModel
// ─────────────────────────────────────────────
@MainActor
final class ParentViewModel: ObservableObject {

    // ── Profile ────────────────────────────
    @Published var parentName: String = "MOM"

    // ── Balance ────────────────────────────
    @Published var balance: Double = 1900

    // ── Stats ──────────────────────────────
    @Published var activeChildren: Int = 3
    @Published var moneySent: Double   = 1000
    @Published var activeGoals: Int    = 3

    // ── Activity ───────────────────────────
    // Starts EMPTY for a brand new user.
    // Populated when parent takes actions.
    @Published var activity: [ActivityItem] = []

    // ── Allowance schedule ─────────────────
    // nil = no schedule set yet → no reminder shown
    @Published var allowanceSchedule: AllowanceSchedule? = nil

    // ── Reminder logic ─────────────────────
    // Returns reminder text if due within 2 days, else nil
    var reminderText: String? {
        guard let schedule = allowanceSchedule else { return nil }
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to:   Calendar.current.startOfDay(for: schedule.nextDueDate)
        ).day ?? 999

        switch days {
        case 0:  return "\(schedule.childName)'s allowance is due today!"
        case 1:  return "\(schedule.childName)'s allowance is due tomorrow"
        case 2:  return "\(schedule.childName)'s allowance is due in 2 days"
        default: return nil
        }
    }

    // ── Add money ──────────────────────────
    func addToBalance(_ amount: Double) {
        balance += amount
        moneySent += amount

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"

        let newItem = ActivityItem(
            title:   "You added \(formatted) SAR to balance",
            meta:    "Today · Just now",
            isToday: true
        )
        activity.insert(newItem, at: 0)
    }

    // ── Fake demo data loader ───────────────
    // Call this ONLY for demo/preview — real data comes from Supabase in Phase 2
    func loadFakeData() {
        balance        = 1900
        moneySent      = 1000
        activeChildren = 3
        activeGoals    = 3

        activity = [
            ActivityItem(title: "You added 500 SAR to balance",      meta: "Today · 10 min ago",              isToday: true),
            ActivityItem(title: "You transferred 50 SAR to Shahad",  meta: "Today · Allowance",               isToday: true),
            ActivityItem(title: "Shahad set up a goal",               meta: "Yesterday · PlayStation · 150 SAR", isToday: false),
            ActivityItem(title: "Shahad achieved her goal",           meta: "Yesterday · PlayStation",         isToday: false),
            ActivityItem(title: "You set up a reminder",              meta: "Mon · Every Thursday · weekly",   isToday: false),
            ActivityItem(title: "You sent Eidiya to all children",    meta: "Last week · 300 SAR",             isToday: false),
        ]

        // Demo schedule — 2 days from now
        allowanceSchedule = AllowanceSchedule(
            childName:   "Shahad",
            nextDueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        )
    }
}