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
// MARK: - Allowance Schedule (supports multiple)
// ─────────────────────────────────────────────
struct AllowanceSchedule: Codable, Identifiable {
    let id:          UUID
    let childName:   String
    var nextDueDate: Date
    let isWeekly:    Bool
    let weekDay:     String? // "Sun","Mon","Tue","Wed","Thu","Fri","Sat"

    init(id: UUID = UUID(), childName: String, nextDueDate: Date,
         isWeekly: Bool = false, weekDay: String? = nil) {
        self.id          = id
        self.childName   = childName
        self.nextDueDate = nextDueDate
        self.isWeekly    = isWeekly
        self.weekDay     = weekDay
    }
}

// ─────────────────────────────────────────────
// MARK: - ParentViewModel
// ─────────────────────────────────────────────
@MainActor
final class ParentViewModel: ObservableObject {

    @Published var parentName: String        = ""
    @Published var parentAvatar: String      = "🧑🏽"
    @Published var balance: Double           = 0
    @Published var activeChildren: Int       = 0
    @Published var moneySent: Double         = 0
    @Published var activeGoals: Int          = 0
    @Published var activity: [ActivityItem]  = []
    @Published var isLoading: Bool           = false

    // ── Multiple reminders stored in UserDefaults ──
    @Published var allowanceSchedules: [AllowanceSchedule] = [] {
        didSet { saveReminders() }
    }

    var parentId: UUID? = nil

    // ── Active reminders (expired custom dates removed, weekly auto-advanced) ──
    var activeSchedules: [AllowanceSchedule] {
        let today = Calendar.current.startOfDay(for: Date())
        return allowanceSchedules.compactMap { schedule in
            var s = schedule
            if s.isWeekly {
                // If due date has passed, advance to next occurrence of the same weekday
                while Calendar.current.startOfDay(for: s.nextDueDate) < today {
                    s.nextDueDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: s.nextDueDate) ?? s.nextDueDate
                }
                return s
            } else {
                // Custom date: show until date passes
                return Calendar.current.startOfDay(for: s.nextDueDate) >= today ? s : nil
            }
        }
    }

    // ── Keep old property for backward compatibility ──
    var allowanceSchedule: AllowanceSchedule? { activeSchedules.first }

    // ── Reminder text for a single schedule ──
    func reminderText(for schedule: AllowanceSchedule) -> String {
        let days = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to:   Calendar.current.startOfDay(for: schedule.nextDueDate)
        ).day ?? 0
        switch days {
        case 0:  return "⏰ \(schedule.childName)'s allowance is due today!"
        case 1:  return "⏰ \(schedule.childName)'s allowance is due tomorrow"
        default: return "⏰ \(schedule.childName)'s allowance is due in \(days) days"
        }
    }

    // ── Legacy single reminderText ──
    var reminderText: String? {
        guard let s = activeSchedules.first else { return nil }
        return reminderText(for: s)
    }

    // ─────────────────────────────────────────
    // MARK: - Reminders persistence
    // ─────────────────────────────────────────
    private let remindersKey = "nafaqati_reminders"

    func loadReminders() {
        guard let data = UserDefaults.standard.data(forKey: remindersKey),
              let decoded = try? JSONDecoder().decode([AllowanceSchedule].self, from: data)
        else { return }
        allowanceSchedules = decoded
    }

    private func saveReminders() {
        if let encoded = try? JSONEncoder().encode(allowanceSchedules) {
            UserDefaults.standard.set(encoded, forKey: remindersKey)
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Set / Remove reminder
    // ─────────────────────────────────────────
    func setReminder(childName: String, nextDueDate: Date,
                     isWeekly: Bool = true, weekDay: String? = nil) {
        // Remove existing reminder for same child then add new one
        allowanceSchedules.removeAll { $0.childName == childName }
        let schedule = AllowanceSchedule(
            childName:   childName,
            nextDueDate: nextDueDate,
            isWeekly:    isWeekly,
            weekDay:     weekDay)
        allowanceSchedules.append(schedule)
        Task {
            await logActivity(
                title: "You set up a reminder for \(childName)",
                meta:  "Today · \(childName)")
        }
    }

    func removeReminder(for childName: String) {
        allowanceSchedules.removeAll { $0.childName == childName }
    }

    // ─────────────────────────────────────────
    // MARK: - Load all parent data from Supabase
    // ─────────────────────────────────────────
    func loadFromSupabase(parentId: UUID) async {
        self.parentId = parentId
        isLoading     = true
        loadReminders() // Load saved reminders on start

        do {
            struct ParentRow: Decodable {
                let name:      String
                let avatarUrl: String?
                let balance:   Double?
                enum CodingKeys: String, CodingKey {
                    case name
                    case avatarUrl = "avatar_url"
                    case balance
                }
            }
            let parentRow: ParentRow = try await supabase
                .from("parent")
                .select("name, avatar_url, balance")
                .eq("id", value: parentId.uuidString)
                .single()
                .execute()
                .value

            let children: [ChildProfile] = try await supabase
                .from("child_profile")
                .select()
                .eq("parent_id", value: parentId.uuidString)
                .execute()
                .value

            var goalsCount = 0
            if !children.isEmpty {
                let allGoals: [Goal] = try await supabase
                    .from("goals")
                    .select()
                    .in("child_id", values: children.map { $0.id.uuidString })
                    .eq("status", value: "approved")
                    .execute()
                    .value
                goalsCount = allGoals.count
            }

            let acts: [ParentActivityRow] = try await supabase
                .from("parent_activity")
                .select()
                .eq("parent_id", value: parentId.uuidString)
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value

            let activityItems = acts.map { row in
                ActivityItem(
                    title:   row.title,
                    meta:    row.meta ?? "",
                    isToday: Calendar.current.isDateInToday(row.createdAt ?? Date()))
            }

            var totalSent: Double = 0
            if !children.isEmpty {
                let allJars: [Jar] = try await supabase
                    .from("jars")
                    .select()
                    .in("child_id", values: children.map { $0.id.uuidString })
                    .execute()
                    .value
                totalSent = allJars.reduce(0) { $0 + $1.balance }
            }

            parentName     = parentRow.name
            parentAvatar   = parentRow.avatarUrl ?? "🧑🏽"
            balance        = parentRow.balance ?? 0
            activeChildren = children.count
            activeGoals    = goalsCount
            moneySent      = totalSent
            activity       = activityItems

        } catch {
            print("❌ loadFromSupabase: \(error)")
        }

        isLoading = false
    }

    // ─────────────────────────────────────────
    // MARK: - Add to balance
    // ─────────────────────────────────────────
    func addToBalance(_ amount: Double) async {
        guard let parentId = parentId else { return }
        let newBalance = balance + amount
        do {
            try await supabase
                .from("parent")
                .update(["balance": newBalance])
                .eq("id", value: parentId.uuidString)
                .execute()
            balance = newBalance
            await logActivity(
                title: "You added \(Int(amount)) SAR to balance",
                meta:  "Today · Just now")
        } catch {
            print("❌ addToBalance: \(error)")
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Send money
    // ─────────────────────────────────────────
    func sendMoney(to childName: String, amount: Double, type: String) async {
        guard let parentId = parentId else { return }
        let deduct     = min(amount, balance)
        let newBalance = max(0, balance - deduct)
        do {
            try await supabase
                .from("parent")
                .update(["balance": newBalance])
                .eq("id", value: parentId.uuidString)
                .execute()
            balance    = newBalance
            moneySent += deduct
            await logActivity(
                title: "You transferred \(Int(deduct)) SAR to \(childName)",
                meta:  "Today · \(type)")
        } catch {
            print("❌ sendMoney: \(error)")
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Log activity
    // ─────────────────────────────────────────
    func logActivity(title: String, meta: String) async {
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
            activity.insert(
                ActivityItem(title: title, meta: meta, isToday: true),
                at: 0)
        } catch {
            print("❌ logActivity: \(error)")
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Supabase row model
// ─────────────────────────────────────────────
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
