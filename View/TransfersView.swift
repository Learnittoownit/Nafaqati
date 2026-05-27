// TransfersView.swift
// Nafaqati
//
// The Transfers tab — Send Money, Set Reminder, Pending Requests, Transaction History.
// Children are loaded from Supabase. Pending requests and history start empty.
// Phase 2: connect pending requests and history to Supabase realtime.

import SwiftUI
import Supabase

// ═══════════════════════════════════════════════
// MARK: - Local Models
// ═══════════════════════════════════════════════

struct PendingRequest: Identifiable {
    let id = UUID()
    let childName: String
    let childInitial: String
    let action: String
    let time: String
    let amount: Double
    let description: String
    let isPositive: Bool
    var isApproved: Bool? = nil
}

struct TransferRecord: Identifiable {
    let id = UUID()
    let type: String
    let childName: String
    let date: String
    let amount: Double
}

enum SendMoneyType: String, CaseIterable {
    case allowance = "Allowance"
    case eidiya    = "Eidiya"
    case gift      = "Gift"

    var emoji: String {
        switch self {
        case .allowance: return "💰"
        case .eidiya:    return "🌙"
        case .gift:      return "🎁"
        }
    }
}

enum ReminderMode     { case `repeat`, setOwn }
enum RepeatFrequency  { case weekly, monthly }

// ═══════════════════════════════════════════════
// MARK: - TransfersView
// ═══════════════════════════════════════════════

struct TransfersView: View {
    @EnvironmentObject var parentVM: ParentViewModel
    @EnvironmentObject var authVM:   AuthViewModel

    // Sheet
    @State private var showSendMoney = false

    // Reminder
    @State private var reminderExpanded  = false
    @State private var reminderMode: ReminderMode     = .repeat
    @State private var selectedWeekDay   = "Thu"
    @State private var repeatFreq: RepeatFrequency    = .weekly
    @State private var selectedDates: Set<Int>        = []

    // History
    @State private var historyExpanded = false

    // Real children from Supabase
    @State private var children: [ChildProfile] = []
    @State private var isLoadingChildren = false

    // Pending requests — starts empty, Phase 2: Supabase realtime
    @State private var pendingRequests: [PendingRequest] = []

    // Transaction history — starts empty, Phase 2: fetch from Supabase
    @State private var transactions: [TransferRecord] = []

    let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var reminderSubtitle: String {
        if reminderMode == .repeat {
            return "Every \(selectedWeekDay) · \(repeatFreq == .weekly ? "weekly" : "monthly")"
        } else {
            let sorted = selectedDates.sorted()
            if sorted.isEmpty { return "Never miss an allowance" }
            return sorted.prefix(4).map { "May \($0)" }.joined(separator: " · ")
        }
    }

    var pendingCount: Int { pendingRequests.filter { $0.isApproved == nil }.count }

    var body: some View {
        ZStack(alignment: .top) {

            Color(hex: "2D6DAB")
                .ignoresSafeArea(edges: .top)
                .frame(height: 200)
                .frame(maxHeight: .infinity, alignment: .top)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Header ────────────────────────────
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Transfers")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Text("Send, schedule and approve")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    .padding(.bottom, 24)

                    // ── Content ───────────────────────────
                    VStack(spacing: 14) {

                        // Send Money button
                        Button { showSendMoney = true } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Send Money")
                                    .font(.system(size: 17, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(width: 250)
                            .frame(height: 66)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "1A3F7A"), Color(hex: "2D6DAB"), Color(hex: "1A3F7A")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Color(hex: "1B3A6B").opacity(0.5), radius: 6, x: 0, y: 3)
                        }

                        // Reminder
                        ReminderCard(
                            expanded:      $reminderExpanded,
                            mode:          $reminderMode,
                            selectedDay:   $selectedWeekDay,
                            frequency:     $repeatFreq,
                            selectedDates: $selectedDates,
                            subtitle:      reminderSubtitle,
                            weekDays:      weekDays
                        )

                        // Pending requests
                        if pendingCount > 0 {
                            PendingRequestsSection(requests: $pendingRequests)
                        } else {
                            EmptyPendingCard()
                        }

                        // Transaction history
                        TransactionHistorySection(
                            expanded:     $historyExpanded,
                            transactions: transactions
                        )
                    }
                    .padding(16)
                    .padding(.bottom, 110)
                    .background(
                        Color(hex: "E8EDF2")
                            .cornerRadius(50, corners: [.topLeft, .topRight])
                    )
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color(hex: "E8EDF2"))
        .task {
            await fetchChildren()
        }
        .sheet(isPresented: $showSendMoney) {
            SendMoneySheet(
                isPresented: $showSendMoney,
                children: children,
                transactions: $transactions
            )
            .environmentObject(parentVM)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // ── Fetch real children from Supabase ──
    private func fetchChildren() async {
        guard let parentId = authVM.currentUserId else { return }
        isLoadingChildren = true
        do {
            let result: [ChildProfile] = try await supabase
                .from("child_profile")
                .select()
                .eq("parent_id", value: parentId.uuidString)
                .execute()
                .value
            children = result
        } catch {
            print("❌ fetchChildren error: \(error)")
        }
        isLoadingChildren = false
    }
}

// ═══════════════════════════════════════════════
// MARK: - Empty Pending Card
// ═══════════════════════════════════════════════

struct EmptyPendingCard: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 20))
                .foregroundColor(Color.nafTextGray)
            Text("No pending requests")
                .font(.system(size: 14))
                .foregroundColor(Color.nafTextGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// ═══════════════════════════════════════════════
// MARK: - Reminder Card
// ═══════════════════════════════════════════════

struct ReminderCard: View {
    @Binding var expanded: Bool
    @Binding var mode: ReminderMode
    @Binding var selectedDay: String
    @Binding var frequency: RepeatFrequency
    @Binding var selectedDates: Set<Int>
    let subtitle: String
    let weekDays: [String]

    var body: some View {
        VStack(spacing: 0) {

            Button {
                withAnimation(.spring(response: 0.35)) { expanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "EBF0F8"))
                            .frame(width: 38, height: 38)
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "2D6DAB"))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Set a reminder")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "1B3A6B"))
                        Text(expanded ? subtitle : "Never miss an allowance")
                            .font(.system(size: 12))
                            .foregroundColor(Color.nafTextGray)
                    }
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.nafTextGray)
                }
                .padding(14)
            }

            if expanded {
                VStack(spacing: 16) {
                    Divider().padding(.horizontal, 14)

                    HStack(spacing: 10) {
                        ReminderModeButton(title: "Repeat",     isSelected: mode == .repeat)  { withAnimation { mode = .repeat } }
                        ReminderModeButton(title: "Set my own", isSelected: mode == .setOwn)  { withAnimation { mode = .setOwn } }
                    }
                    .padding(.horizontal, 14)

                    if mode == .repeat {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("PICK A DAY OF THE WEEK")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(0.8)
                                .foregroundColor(Color.nafTextGray)
                                .padding(.horizontal, 14)

                            HStack(spacing: 6) {
                                ForEach(weekDays, id: \.self) { day in
                                    Button { selectedDay = day } label: {
                                        Text(day)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(selectedDay == day ? .white : Color.nafTextGray)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 34)
                                            .background(selectedDay == day ? Color(hex: "2D6DAB") : Color.white)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(selectedDay == day ? Color.clear : Color.nafLightCard, lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 14)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("REPEAT EVERY")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(0.8)
                                .foregroundColor(Color.nafTextGray)
                                .padding(.horizontal, 14)

                            HStack(spacing: 10) {
                                FreqButton(title: "Weekly",  isSelected: frequency == .weekly)  { frequency = .weekly }
                                FreqButton(title: "Monthly", isSelected: frequency == .monthly) { frequency = .monthly }
                            }
                            .padding(.horizontal, 14)
                        }

                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pick a specific date")
                                .font(.system(size: 12))
                                .foregroundColor(Color.nafTextGray)
                                .padding(.horizontal, 14)

                            MultiDateCalendar(selectedDates: $selectedDates)
                                .padding(.horizontal, 14)
                        }
                    }
                }
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(expanded ? Color(hex: "2D6DAB").opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
    }
}

struct ReminderModeButton: View {
    let title: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? Color(hex: "2D6DAB") : Color.nafTextGray)
                .frame(maxWidth: .infinity).frame(height: 40)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color(hex: "2D6DAB") : Color.nafLightCard, lineWidth: 1.5))
        }
    }
}

struct FreqButton: View {
    let title: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : Color.nafTextGray)
                .frame(maxWidth: .infinity).frame(height: 42)
                .background(isSelected ? Color(hex: "2D6DAB") : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.clear : Color.nafLightCard, lineWidth: 1.5))
        }
    }
}

// ═══════════════════════════════════════════════
// MARK: - Multi-Date Calendar
// ═══════════════════════════════════════════════

struct MultiDateCalendar: View {
    @Binding var selectedDates: Set<Int>
    @State private var displayDate = Date()

    private let weekHeaders = ["S", "M", "T", "W", "T", "F", "S"]

    private var monthTitle: String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f.string(from: displayDate)
    }

    private var todayDay: Int {
        let c = Calendar.current
        let t = c.dateComponents([.year, .month], from: Date())
        let d = c.dateComponents([.year, .month], from: displayDate)
        return (t.year == d.year && t.month == d.month) ? c.component(.day, from: Date()) : 0
    }

    private var daysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: displayDate)?.count ?? 30
    }

    private var firstWeekday: Int {
        let comps = Calendar.current.dateComponents([.year, .month], from: displayDate)
        let firstDay = Calendar.current.date(from: comps)!
        return Calendar.current.component(.weekday, from: firstDay) - 1
    }

    private var grid: [[Int]] {
        var result: [[Int]] = []
        var day = 1; var col = firstWeekday
        var row = [Int](repeating: 0, count: 7)
        while day <= daysInMonth {
            row[col] = day; col += 1
            if col == 7 { result.append(row); row = [Int](repeating: 0, count: 7); col = 0 }
            day += 1
        }
        if col > 0 { result.append(row) }
        return result
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    displayDate = Calendar.current.date(byAdding: .month, value: -1, to: displayDate) ?? displayDate
                } label: {
                    Image(systemName: "chevron.left").font(.system(size: 13)).foregroundColor(Color.nafTextGray)
                }
                Spacer()
                Text(monthTitle).font(.system(size: 14, weight: .semibold)).foregroundColor(Color(hex: "1B3A6B"))
                Spacer()
                Button {
                    displayDate = Calendar.current.date(byAdding: .month, value: 1, to: displayDate) ?? displayDate
                } label: {
                    Image(systemName: "chevron.right").font(.system(size: 13)).foregroundColor(Color.nafTextGray)
                }
            }

            HStack(spacing: 0) {
                ForEach(weekHeaders, id: \.self) { h in
                    Text(h).font(.system(size: 11, weight: .medium)).foregroundColor(Color.nafTextGray).frame(maxWidth: .infinity)
                }
            }

            ForEach(0..<grid.count, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(0..<7) { c in
                        let day = grid[r][c]
                        if day == 0 {
                            Color.clear.frame(maxWidth: .infinity).frame(height: 34)
                        } else {
                            let isSelected = selectedDates.contains(day)
                            let isToday    = day == todayDay
                            Button {
                                if isSelected { selectedDates.remove(day) } else { selectedDates.insert(day) }
                            } label: {
                                Text("\(day)")
                                    .font(.system(size: 13, weight: isSelected ? .bold : .regular))
                                    .foregroundColor(isSelected ? .white : isToday ? Color(hex: "2D6DAB") : Color(hex: "1B3A6B"))
                                    .frame(maxWidth: .infinity).frame(height: 34)
                                    .background(isSelected ? Color(hex: "2D6DAB") : Color.clear)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(isToday && !isSelected ? Color(hex: "2D6DAB") : Color.clear, lineWidth: 1.5))
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "2D6DAB").opacity(0.3), lineWidth: 1))
    }
}

// ═══════════════════════════════════════════════
// MARK: - Pending Requests Section
// ═══════════════════════════════════════════════

struct PendingRequestsSection: View {
    @Binding var requests: [PendingRequest]
    var pendingCount: Int { requests.filter { $0.isApproved == nil }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(pendingCount) PENDING REQUESTS")
                .font(.system(size: 11, weight: .bold)).tracking(0.8)
                .foregroundColor(Color.nafTextGray).padding(.horizontal, 4)

            ForEach(requests.indices, id: \.self) { i in
                if requests[i].isApproved == nil {
                    PendingRequestCard(request: $requests[i])
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct PendingRequestCard: View {
    @Binding var request: PendingRequest

    var pillBg:      Color { request.isPositive ? Color(hex: "FFF3DC") : Color(hex: "FDEAEA") }
    var pillText:    Color { request.isPositive ? Color(hex: "B87A00") : Color(hex: "C0392B") }
    var amountColor: Color { request.isPositive ? Color(hex: "2D7A4F") : Color(hex: "C0392B") }
    var amountText:  String { request.isPositive ? "+\(Int(request.amount)) SAR" : "\(Int(request.amount)) SAR" }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(Color(hex: "EBF0F8")).frame(width: 40, height: 40)
                    Text(request.childInitial).font(.system(size: 16, weight: .bold)).foregroundColor(Color(hex: "2D6DAB"))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(request.childName) \(request.action)").font(.system(size: 14, weight: .semibold)).foregroundColor(Color(hex: "1B3A6B"))
                    Text(request.time).font(.system(size: 12)).foregroundColor(Color.nafTextGray)
                }
                Spacer()
                Text(amountText).font(.system(size: 15, weight: .bold)).foregroundColor(amountColor)
            }

            Text(request.description)
                .font(.system(size: 13, weight: .medium)).foregroundColor(pillText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(pillBg).clipShape(RoundedRectangle(cornerRadius: 10))

            HStack(spacing: 10) {
                Button { withAnimation { request.isApproved = true } } label: {
                    Text("Approve").font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 42)
                        .background(Color(hex: "2D7A4F")).clipShape(RoundedRectangle(cornerRadius: 10))
                }
                Button { withAnimation { request.isApproved = false } } label: {
                    Text("Decline").font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 42)
                        .background(Color(hex: "8B1A1A")).clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(14)
        .background(Color(hex: "F9FAFB"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// ═══════════════════════════════════════════════
// MARK: - Transaction History Section
// ═══════════════════════════════════════════════

struct TransactionHistorySection: View {
    @Binding var expanded: Bool
    let transactions: [TransferRecord]

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35)) { expanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(Color(hex: "EBF0F8")).frame(width: 38, height: 38)
                        Image(systemName: "list.bullet.rectangle").font(.system(size: 16)).foregroundColor(Color(hex: "2D6DAB"))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Transaction History").font(.system(size: 15, weight: .semibold)).foregroundColor(Color(hex: "1B3A6B"))
                        Text("All your transfers").font(.system(size: 12)).foregroundColor(Color.nafTextGray)
                    }
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .medium)).foregroundColor(Color.nafTextGray)
                }
                .padding(14)
            }

            if expanded {
                Divider().padding(.horizontal, 14)

                if transactions.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 28)).foregroundColor(Color.nafTextGray)
                        Text("No transfers yet")
                            .font(.system(size: 14)).foregroundColor(Color.nafTextGray)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 28)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(transactions.enumerated()), id: \.element.id) { idx, record in
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("\(record.type) → \(record.childName)")
                                        .font(.system(size: 14, weight: .medium)).foregroundColor(Color(hex: "1B3A6B"))
                                    Text(record.date).font(.system(size: 12)).foregroundColor(Color.nafTextGray)
                                }
                                Spacer()
                                Text("-\(Int(record.amount)) SAR")
                                    .font(.system(size: 14, weight: .semibold)).foregroundColor(Color(hex: "C0392B"))
                            }
                            .padding(.horizontal, 14).padding(.vertical, 12)
                            if idx < transactions.count - 1 { Divider().padding(.horizontal, 14) }
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// ═══════════════════════════════════════════════
// MARK: - Send Money Sheet
// ═══════════════════════════════════════════════

struct SendMoneySheet: View {
    @Binding var isPresented: Bool
    let children: [ChildProfile]           // real children from Supabase
    @Binding var transactions: [TransferRecord]
    @EnvironmentObject var parentVM: ParentViewModel

    @State private var selectedType: SendMoneyType = .allowance
    @State private var selectedChildId: UUID?      = nil
    @State private var amount    = ""
    @State private var note      = ""
    @State private var showNote      = false
    @State private var showVoiceNote = false

    var canSend: Bool {
        guard let val = Double(amount) else { return false }
        return val > 0 && (selectedChildId != nil || sendToAll)
    }

    @State private var sendToAll = false

    var selectedChildName: String {
        if sendToAll { return "All" }
        return children.first(where: { $0.id == selectedChildId })?.name ?? ""
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                Capsule()
                    .fill(Color.nafTextGray.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12).padding(.bottom, 20)

                Text("Send money")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "1B3A6B"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)

                Spacer().frame(height: 20)

                // ── Type selector ──────────────────
                HStack(spacing: 10) {
                    ForEach(SendMoneyType.allCases, id: \.self) { type in
                        Button { withAnimation { selectedType = type } } label: {
                            HStack(spacing: 5) {
                                Text(type.emoji).font(.system(size: 14))
                                Text(type.rawValue)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(selectedType == type ? Color(hex: "2D6DAB") : Color.nafTextGray)
                            }
                            .padding(.horizontal, 14).padding(.vertical, 9)
                            .background(Color.white).clipShape(Capsule())
                            .overlay(Capsule().stroke(selectedType == type ? Color(hex: "2D6DAB") : Color.nafLightCard, lineWidth: 1.5))
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 20)

                // ── For who? ───────────────────────
                VStack(alignment: .leading, spacing: 10) {
                    Text("For who?")
                        .font(.system(size: 13)).foregroundColor(Color.nafTextGray)
                        .padding(.horizontal, 24)

                    if children.isEmpty {
                        Text("No children added yet")
                            .font(.system(size: 13)).foregroundColor(Color.nafTextGray)
                            .padding(.horizontal, 24)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                // Individual children
                                ForEach(children) { child in
                                    let isSelected = !sendToAll && selectedChildId == child.id
                                    Button {
                                        sendToAll = false
                                        selectedChildId = child.id
                                    } label: {
                                        VStack(spacing: 4) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color(hex: "F0F4FA"))
                                                    .frame(width: 46, height: 46)
                                                    .overlay(Circle().stroke(isSelected ? Color(hex: "2D6DAB") : Color.clear, lineWidth: 2))
                                                Text(String(child.name.prefix(1)))
                                                    .font(.system(size: 17, weight: .bold))
                                                    .foregroundColor(isSelected ? Color(hex: "2D6DAB") : Color.nafTextGray)
                                            }
                                            Text(child.name)
                                                .font(.system(size: 11))
                                                .foregroundColor(isSelected ? Color(hex: "2D6DAB") : Color.nafTextGray)
                                        }
                                    }
                                }

                                // "All" option
                                Button {
                                    sendToAll = true
                                    selectedChildId = nil
                                } label: {
                                    VStack(spacing: 4) {
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: "F0F4FA"))
                                                .frame(width: 46, height: 46)
                                                .overlay(Circle().stroke(sendToAll ? Color(hex: "2D6DAB") : Color.clear, lineWidth: 2))
                                            Text("All")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(sendToAll ? Color(hex: "2D6DAB") : Color.nafTextGray)
                                        }
                                        Text("All")
                                            .font(.system(size: 11))
                                            .foregroundColor(sendToAll ? Color(hex: "2D6DAB") : Color.nafTextGray)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                }

                Spacer().frame(height: 20)

                // ── Amount ─────────────────────────
                VStack(alignment: .leading, spacing: 8) {
                    Text("Amount (SAR)")
                        .font(.system(size: 13)).foregroundColor(Color.nafTextGray)

                    HStack(spacing: 10) {
                        TextField("Enter amount", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 16)).foregroundColor(Color(hex: "1B3A6B"))
                            .padding(14)
                            .background(Color(hex: "F5F7FA"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button { withAnimation { showVoiceNote.toggle() } } label: {
                            ZStack {
                                Circle().fill(Color(hex: "2D6DAB")).frame(width: 46, height: 46)
                                Image(systemName: "mic.fill").font(.system(size: 18)).foregroundColor(.white)
                            }
                        }

                        Button { withAnimation { showNote.toggle() } } label: {
                            ZStack {
                                Circle().fill(Color(hex: "F0F0F0")).frame(width: 46, height: 46)
                                Image(systemName: "pencil").font(.system(size: 18)).foregroundColor(Color.nafTextGray)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)

                // ── Note ───────────────────────────
                if showNote {
                    Spacer().frame(height: 16)
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $note)
                            .font(.system(size: 14)).foregroundColor(Color(hex: "1B3A6B"))
                            .frame(height: 90).padding(8)
                            .background(Color(hex: "F5F7FA"))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.nafLightCard, lineWidth: 1))
                        if note.isEmpty {
                            Text("Write a note to your child...")
                                .font(.system(size: 14)).foregroundColor(Color.nafTextGray)
                                .padding(16).allowsHitTesting(false)
                        }
                    }
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // ── Voice note ─────────────────────
                if showVoiceNote {
                    Spacer().frame(height: 14)
                    VStack(spacing: 10) {
                        Text("Tap to record a voice note")
                            .font(.system(size: 13)).foregroundColor(.white.opacity(0.8))
                        Button { } label: {
                            ZStack {
                                Circle().fill(Color(hex: "2D6DAB")).frame(width: 54, height: 54)
                                Image(systemName: "mic.fill").font(.system(size: 22)).foregroundColor(.white)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(Color(hex: "1B3A6B"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer().frame(height: 24)

                // ── Send ───────────────────────────
                Button {
                    guard canSend, let amt = Double(amount), amt > 0 else { return }

                    // 1. Update parent balance stats
                    parentVM.balance   -= amt
                    parentVM.moneySent += amt

                    // 2. Add to Home tab activity feed
                    let item = ActivityItem(
                        title:   "You transferred \(Int(amt)) SAR to \(selectedChildName)",
                        meta:    "Today · \(selectedType.rawValue)",
                        isToday: true
                    )
                    parentVM.activity.insert(item, at: 0)

                    // 3. Add to Transfers tab Transaction History
                    let record = TransferRecord(
                        type:      selectedType.rawValue,
                        childName: selectedChildName,
                        date:      "Today",
                        amount:    amt
                    )
                    transactions.insert(record, at: 0)

                    isPresented = false
                } label: {
                    Text("Send")
                        .font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                        .frame(width: 200).frame(height: 65)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "1A3F7A"), Color(hex: "2D6DAB"), Color(hex: "1A3F7A")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: Color(hex: "1B3A6B").opacity(0.4), radius: 8, x: 0, y: 4)
                        .opacity(canSend ? 1.0 : 0.5)
                }
                .disabled(!canSend)
                .padding(.horizontal, 24).padding(.bottom, 40)
            }
        }
        .background(Color.white)
    }
}

// ─────────────────────────────────────────────
// MARK: - Preview
// ─────────────────────────────────────────────

#Preview {
    TransfersView()
        .environmentObject(ParentViewModel())
        .environmentObject(AuthViewModel())
}

