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
    var goalId: UUID? = nil

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

enum ReminderMode    { case `repeat`, setOwn }
enum RepeatFrequency { case weekly, monthly }

// ═══════════════════════════════════════════════
// MARK: - TransfersView
// ═══════════════════════════════════════════════

struct TransfersView: View {
    @EnvironmentObject var parentVM: ParentViewModel
    @EnvironmentObject var authVM:   AuthViewModel

    @State private var showSendMoney     = false
    @State private var reminderExpanded  = false
    @State private var reminderMode: ReminderMode    = .repeat
    @State private var selectedWeekDay   = "Thu"
    @State private var repeatFreq: RepeatFrequency   = .weekly
    @State private var selectedDates: Set<Int>       = []
    @State private var historyExpanded   = false
    @State private var children: [ChildProfile]      = []
    @State private var isLoadingChildren = false
    @State private var pendingRequests: [PendingRequest] = []
    @State private var transactions: [TransferRecord]    = []

    let weekDays = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]

    var reminderSubtitle: String {
        if reminderMode == .repeat {
            return "Every \(selectedWeekDay) · \(repeatFreq == .weekly ? "weekly" : "monthly")"
        } else {
            let sorted = selectedDates.sorted()
            if sorted.isEmpty { return "Never miss an allowance" }
            return sorted.prefix(4).map { "May \($0)" }.joined(separator: " · ")
        }
    }

    var pendingCount: Int {
        pendingRequests.filter { $0.isApproved == nil }.count
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                Color(hex: "2D6DAB")
                    .frame(height: UIScreen.main.bounds.height
                           * 0.38)
                Color(hex: "E8EDF2")
            }
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Transfers")
                            .font(.system(
                                size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Text("Send, schedule and approve")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity,
                           alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    .padding(.bottom, 24)

                    VStack(spacing: 14) {

                        Button { showSendMoney = true } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(
                                        size: 16,
                                        weight: .bold))
                                Text("Send Money")
                                    .font(.system(
                                        size: 17,
                                        weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(width: 250)
                            .frame(height: 66)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "1A3F7A"),
                                        Color(hex: "2D6DAB"),
                                        Color(hex: "1A3F7A")],
                                    startPoint: .leading,
                                    endPoint: .trailing))
                            .clipShape(RoundedRectangle(
                                cornerRadius: 12))
                            .shadow(
                                color: Color(hex: "1B3A6B")
                                    .opacity(0.5),
                                radius: 6, x: 0, y: 3)
                        }

                        ReminderCard(
                            expanded: $reminderExpanded,
                            mode: $reminderMode,
                            selectedDay: $selectedWeekDay,
                            frequency: $repeatFreq,
                            selectedDates: $selectedDates,
                            subtitle: reminderSubtitle,
                            weekDays: weekDays)

                        if pendingCount > 0 {
                            PendingRequestsSection(
                                requests: $pendingRequests)
                        } else {
                            EmptyPendingCard()
                        }

                        TransactionHistorySection(
                            expanded: $historyExpanded,
                            transactions: transactions)
                    }
                    .padding(16)
                    .padding(.bottom, 110)
                    .frame(maxWidth: .infinity)
                    .background(
                        Color(hex: "E8EDF2")
                            .cornerRadius(50, corners: [
                                .topLeft, .topRight]))
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .task {
            await fetchChildren()
            await fetchPendingGoals()
        }        .overlay {
            if showSendMoney {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture { showSendMoney = false }
                    SendMoneyPopup(
                        isPresented: $showSendMoney,
                        children: children,
                        transactions: $transactions)
                    .environmentObject(parentVM)
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    private func fetchChildren() async {
        guard let parentId = authVM.currentUserId else {
            return
        }
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
    
    private func fetchPendingGoals() async {
        guard let parentId = authVM.currentUserId else {
            return
        }

        do {
            // Get all children for this parent
            let children: [ChildProfile] = try await supabase
                .from("child_profile")
                .select()
                .eq("parent_id", value: parentId.uuidString)
                .execute()
                .value

            var requests: [PendingRequest] = []

            for child in children {
                let pendingGoals: [Goal] = try await supabase
                    .from("goals")
                    .select()
                    .eq("child_id", value: child.id.uuidString)
                    .eq("status", value: "pending")
                    .execute()
                    .value

                for goal in pendingGoals {
                    requests.append(PendingRequest(
                        childName:    child.name,
                        childInitial: String(
                            child.name.prefix(1)),
                        action:       "wants to set a goal",
                        time:         "Just now",
                        amount:       goal.target,
                        description:  "Goal: \(goal.name) · Target: \(Int(goal.target)) SAR",
                        isPositive:   true,
                        goalId:       goal.id))
                }
            }

            await MainActor.run {
                pendingRequests = requests
            }

        } catch {
            print("❌ fetchPendingGoals: \(error)")
        }
    }
}

// ═══════════════════════════════════════════════
// MARK: - Send Money Popup
// ═══════════════════════════════════════════════

struct SendMoneyPopup: View {
    @Binding var isPresented: Bool
    let children: [ChildProfile]
    @Binding var transactions: [TransferRecord]
    @EnvironmentObject var parentVM: ParentViewModel

    @State private var selectedType: SendMoneyType = .allowance
    @State private var selectedChildId: UUID?      = nil
    @State private var sendToAll   = false
    @State private var amount      = ""
    @State private var note        = ""
    @State private var showNote    = false
    @State private var showVoice   = false
    @State private var showError   = false

    var canSend: Bool {
        guard let val = Double(amount), val > 0 else {
            return false
        }
        return selectedChildId != nil || sendToAll
    }

    var hasEnoughBalance: Bool {
        guard let val = Double(amount) else { return true }
        return parentVM.balance >= val
    }

    var selectedChildName: String {
        if sendToAll { return "All" }
        return children.first(
            where: { $0.id == selectedChildId })?.name ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Send money")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: "1B3A6B"))
                .frame(maxWidth: .infinity,
                       alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 20)

            Spacer().frame(height: 16)

            // Type chips
            HStack(spacing: 10) {
                ForEach(SendMoneyType.allCases,
                        id: \.self) { type in
                    Button {
                        withAnimation { selectedType = type }
                    } label: {
                        HStack(spacing: 5) {
                            Text(type.emoji)
                                .font(.system(size: 13))
                            Text(type.rawValue)
                                .font(.system(
                                    size: 13,
                                    weight: .medium))
                                .foregroundColor(
                                    selectedType == type
                                    ? Color(hex: "2D6DAB")
                                    : Color.nafTextGray)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(
                            selectedType == type
                            ? Color(hex: "2D6DAB")
                            : Color.nafLightCard,
                            lineWidth: 1.5))
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)

            Spacer().frame(height: 16)

            // For who
            VStack(alignment: .leading, spacing: 10) {
                Text("For who?")
                    .font(.system(size: 13))
                    .foregroundColor(Color.nafTextGray)
                    .padding(.horizontal, 20)

                if children.isEmpty {
                    Text("No children linked yet")
                        .font(.system(size: 13))
                        .foregroundColor(Color.nafTextGray)
                        .padding(.horizontal, 20)
                } else {
                    ScrollView(.horizontal,
                               showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(children) { child in
                                let isSel = !sendToAll
                                    && selectedChildId == child.id
                                Button {
                                    sendToAll      = false
                                    selectedChildId = child.id
                                } label: {
                                    VStack(spacing: 4) {
                                        ZStack {
                                            Circle()
                                                .fill(Color(
                                                    hex: "F0F4FA"))
                                                .frame(
                                                    width: 46,
                                                    height: 46)
                                                .overlay(
                                                    Circle()
                                                        .stroke(
                                                            isSel
                                                            ? Color(hex: "2D6DAB")
                                                            : Color.clear,
                                                            lineWidth: 2))
                                            Text(String(
                                                child.name
                                                    .prefix(1)))
                                                .font(.system(
                                                    size: 17,
                                                    weight: .bold))
                                                .foregroundColor(
                                                    isSel
                                                    ? Color(hex: "2D6DAB")
                                                    : Color.nafTextGray)
                                        }
                                        Text(child.name)
                                            .font(.system(
                                                size: 11))
                                            .foregroundColor(
                                                isSel
                                                ? Color(hex: "2D6DAB")
                                                : Color.nafTextGray)
                                    }
                                }
                            }
                            Button {
                                sendToAll      = true
                                selectedChildId = nil
                            } label: {
                                VStack(spacing: 4) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(
                                                hex: "F0F4FA"))
                                            .frame(
                                                width: 46,
                                                height: 46)
                                            .overlay(
                                                Circle()
                                                    .stroke(
                                                        sendToAll
                                                        ? Color(hex: "2D6DAB")
                                                        : Color.clear,
                                                        lineWidth: 2))
                                        Text("All")
                                            .font(.system(
                                                size: 11,
                                                weight: .bold))
                                            .foregroundColor(
                                                sendToAll
                                                ? Color(hex: "2D6DAB")
                                                : Color.nafTextGray)
                                    }
                                    Text("All")
                                        .font(.system(size: 11))
                                        .foregroundColor(
                                            sendToAll
                                            ? Color(hex: "2D6DAB")
                                            : Color.nafTextGray)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }

            Spacer().frame(height: 16)

            // Amount
            VStack(alignment: .leading, spacing: 8) {
                Text("Amount (SAR)")
                    .font(.system(size: 13))
                    .foregroundColor(Color.nafTextGray)
                HStack(spacing: 10) {
                    TextField("Enter amount", text: $amount)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "1B3A6B"))
                        .padding(14)
                        .background(Color(hex: "F5F7FA"))
                        .clipShape(RoundedRectangle(
                            cornerRadius: 12))
                        .onChange(of: amount) { _ in
                            showError = false
                        }

                    Button {
                        showVoice.toggle()
                        if showVoice { showNote = false }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(showVoice
                                      ? Color(hex: "2D6DAB")
                                      : Color(hex: "F0F0F0"))
                                .frame(width: 46, height: 46)
                            Image(systemName: "mic.fill")
                                .font(.system(size: 18))
                                .foregroundColor(
                                    showVoice
                                    ? .white
                                    : Color.nafTextGray)
                        }
                    }

                    Button {
                        showNote.toggle()
                        if showNote { showVoice = false }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(showNote
                                      ? Color(hex: "2D6DAB")
                                      : Color(hex: "F0F0F0"))
                                .frame(width: 46, height: 46)
                            Image(systemName: "pencil")
                                .font(.system(size: 18))
                                .foregroundColor(
                                    showNote
                                    ? .white
                                    : Color.nafTextGray)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)

            if showNote {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $note)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "1B3A6B"))
                        .frame(height: 80)
                        .padding(8)
                        .background(Color(hex: "F5F7FA"))
                        .clipShape(RoundedRectangle(
                            cornerRadius: 12))
                        .overlay(RoundedRectangle(
                            cornerRadius: 12)
                            .stroke(Color.nafLightCard,
                                    lineWidth: 1))
                    if note.isEmpty {
                        Text("Write a note to your child...")
                            .font(.system(size: 14))
                            .foregroundColor(Color.nafTextGray)
                            .padding(16)
                            .allowsHitTesting(false)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .transition(.opacity.combined(
                    with: .move(edge: .top)))
            }

            if showVoice {
                VStack(spacing: 8) {
                    Text("Tap to record a voice note")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                    Button { } label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "2D6DAB"))
                                .frame(width: 50, height: 50)
                            Image(systemName: "mic.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "1B3A6B"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .transition(.opacity.combined(
                    with: .move(edge: .top)))
            }

            if showError {
                Text("You don't have enough balance to send this amount")
                    .font(.system(
                        size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "C0392B"))
                    .frame(maxWidth: .infinity,
                           alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .transition(.opacity)
            }

            Spacer().frame(height: 16)

            // Send button
            Button {
                guard canSend,
                      let amt = Double(amount),
                      amt > 0 else { return }
                if !hasEnoughBalance {
                    withAnimation { showError = true }
                    return
                }
                Task { await sendAllowance(amount: amt) }
            } label: {
                Text("Send")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        canSend
                        ? LinearGradient(
                            colors: [
                                Color(hex: "1A3F7A"),
                                Color(hex: "2D6DAB"),
                                Color(hex: "1A3F7A")],
                            startPoint: .leading,
                            endPoint: .trailing)
                        : LinearGradient(
                            colors: [
                                Color.nafTextGray,
                                Color.nafTextGray],
                            startPoint: .leading,
                            endPoint: .trailing))
                    .clipShape(RoundedRectangle(
                        cornerRadius: 27))
            }
            .disabled(!canSend)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.2),
                radius: 20, x: 0, y: 8)
    }

    // ── Send allowance to Supabase ────────
    func sendAllowance(amount: Double) async {
        let childrenToSend: [ChildProfile]
        if sendToAll {
            childrenToSend = children
        } else {
            guard let child = children.first(
                where: { $0.id == selectedChildId })
            else { return }
            childrenToSend = [child]
        }

        do {
            for c in childrenToSend {
                let jars: [Jar] = try await supabase
                    .from("jars")
                    .select()
                    .eq("child_id", value: c.id.uuidString)
                    .execute()
                    .value

                let savingAmt   = amount * 0.50
                let spendingAmt = amount * 0.30
                let givingAmt   = amount * 0.20

                for jar in jars {
                    let addAmount: Double
                    switch jar.type {
                    case .saving:   addAmount = savingAmt
                    case .spending: addAmount = spendingAmt
                    case .giving:   addAmount = givingAmt
                    }

                    try await supabase
                        .from("jars")
                        .update([
                            "balance": jar.balance + addAmount
                        ])
                        .eq("id", value: jar.id.uuidString)
                        .execute()

                    struct TransactionInsert: Encodable {
                        let child_id: String
                        let jar_id:   String
                        let type:     String
                        let amount:   Double
                        let source:   String
                        let note:     String
                    }

                    try await supabase
                        .from("transactions")
                        .insert(TransactionInsert(
                            child_id: c.id.uuidString,
                            jar_id:   jar.id.uuidString,
                            type:     "deposit",
                            amount:   addAmount,
                            source:   "allowance",
                            note:     note.isEmpty
                                ? selectedType.rawValue
                                : note))
                        .execute()
                }

                await MainActor.run {
                    parentVM.sendMoney(
                        to:     c.name,
                        amount: amount,
                        type:   selectedType.rawValue)
                    transactions.insert(
                        TransferRecord(
                            type:      selectedType.rawValue,
                            childName: c.name,
                            date:      "Today",
                            amount:    amount),
                        at: 0)
                }
            }

            await MainActor.run {
                isPresented = false
            }

        } catch {
            print("❌ sendAllowance error: \(error)")
        }
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
                withAnimation(.spring(response: 0.35)) {
                    expanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "EBF0F8"))
                            .frame(width: 38, height: 38)
                        Image(systemName:
                            "calendar.badge.clock")
                            .font(.system(size: 16))
                            .foregroundColor(
                                Color(hex: "2D6DAB"))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Set a reminder")
                            .font(.system(
                                size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "1B3A6B"))
                        Text(expanded
                             ? subtitle
                             : "Never miss an allowance")
                            .font(.system(size: 12))
                            .foregroundColor(Color.nafTextGray)
                    }
                    Spacer()
                    Image(systemName: expanded
                          ? "chevron.up" : "chevron.down")
                        .font(.system(
                            size: 13, weight: .medium))
                        .foregroundColor(Color.nafTextGray)
                }
                .padding(14)
            }

            if expanded {
                VStack(spacing: 16) {
                    Divider().padding(.horizontal, 14)
                    HStack(spacing: 10) {
                        ReminderModeButton(
                            title: "Repeat",
                            isSelected: mode == .repeat) {
                            withAnimation { mode = .repeat }
                        }
                        ReminderModeButton(
                            title: "Set my own",
                            isSelected: mode == .setOwn) {
                            withAnimation { mode = .setOwn }
                        }
                    }
                    .padding(.horizontal, 14)

                    if mode == .repeat {
                        VStack(alignment: .leading,
                               spacing: 10) {
                            Text("PICK A DAY OF THE WEEK")
                                .font(.system(
                                    size: 10, weight: .bold))
                                .tracking(0.8)
                                .foregroundColor(
                                    Color.nafTextGray)
                                .padding(.horizontal, 14)
                            HStack(spacing: 6) {
                                ForEach(weekDays,
                                        id: \.self) { day in
                                    Button {
                                        selectedDay = day
                                    } label: {
                                        Text(day)
                                            .font(.system(
                                                size: 11,
                                                weight: .medium))
                                            .foregroundColor(
                                                selectedDay == day
                                                ? .white
                                                : Color.nafTextGray)
                                            .frame(maxWidth:
                                                    .infinity)
                                            .frame(height: 34)
                                            .background(
                                                selectedDay == day
                                                ? Color(hex:
                                                    "2D6DAB")
                                                : Color.white)
                                            .clipShape(
                                                RoundedRectangle(
                                                    cornerRadius:
                                                        8))
                                            .overlay(
                                                RoundedRectangle(
                                                    cornerRadius:
                                                        8)
                                                    .stroke(
                                                        selectedDay
                                                        == day
                                                        ? Color.clear
                                                        : Color
                                                            .nafLightCard,
                                                        lineWidth:
                                                            1))
                                    }
                                }
                            }
                            .padding(.horizontal, 14)
                        }

                        VStack(alignment: .leading,
                               spacing: 10) {
                            Text("REPEAT EVERY")
                                .font(.system(
                                    size: 10, weight: .bold))
                                .tracking(0.8)
                                .foregroundColor(
                                    Color.nafTextGray)
                                .padding(.horizontal, 14)
                            HStack(spacing: 10) {
                                FreqButton(
                                    title: "Weekly",
                                    isSelected:
                                        frequency == .weekly) {
                                    frequency = .weekly
                                }
                                FreqButton(
                                    title: "Monthly",
                                    isSelected:
                                        frequency == .monthly) {
                                    frequency = .monthly
                                }
                            }
                            .padding(.horizontal, 14)
                        }
                    } else {
                        VStack(alignment: .leading,
                               spacing: 8) {
                            Text("Pick a specific date")
                                .font(.system(size: 12))
                                .foregroundColor(
                                    Color.nafTextGray)
                                .padding(.horizontal, 14)
                            MultiDateCalendar(
                                selectedDates: $selectedDates)
                                .padding(.horizontal, 14)
                        }
                    }
                }
                .padding(.bottom, 14)
                .transition(.opacity.combined(
                    with: .move(edge: .top)))
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(expanded
                    ? Color(hex: "2D6DAB").opacity(0.5)
                    : Color.clear,
                    lineWidth: 1.5))
    }
}

struct ReminderModeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(
                    isSelected
                    ? Color(hex: "2D6DAB")
                    : Color.nafTextGray)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected
                        ? Color(hex: "2D6DAB")
                        : Color.nafLightCard,
                        lineWidth: 1.5))
        }
    }
}

struct FreqButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(
                    isSelected ? .white : Color.nafTextGray)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    isSelected
                    ? Color(hex: "2D6DAB")
                    : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected
                        ? Color.clear
                        : Color.nafLightCard,
                        lineWidth: 1.5))
        }
    }
}

// ═══════════════════════════════════════════════
// MARK: - Multi-Date Calendar
// ═══════════════════════════════════════════════
struct MultiDateCalendar: View {
    @Binding var selectedDates: Set<Int>
    @State private var displayDate = Date()

    private let weekHeaders = ["S","M","T","W","T","F","S"]

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: displayDate)
    }

    private var todayDay: Int {
        let c = Calendar.current
        let t = c.dateComponents([.year,.month], from: Date())
        let d = c.dateComponents(
            [.year,.month], from: displayDate)
        return (t.year == d.year && t.month == d.month)
            ? c.component(.day, from: Date()) : 0
    }

    private var daysInMonth: Int {
        Calendar.current.range(
            of: .day, in: .month, for: displayDate)?.count ?? 30
    }

    private var firstWeekday: Int {
        let comps = Calendar.current.dateComponents(
            [.year,.month], from: displayDate)
        let first = Calendar.current.date(from: comps)!
        return Calendar.current.component(
            .weekday, from: first) - 1
    }

    private var grid: [[Int]] {
        var result: [[Int]] = []
        var day = 1
        var col = firstWeekday
        var row = [Int](repeating: 0, count: 7)
        while day <= daysInMonth {
            row[col] = day
            col += 1
            if col == 7 {
                result.append(row)
                row = [Int](repeating: 0, count: 7)
                col = 0
            }
            day += 1
        }
        if col > 0 { result.append(row) }
        return result
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    displayDate = Calendar.current.date(
                        byAdding: .month,
                        value: -1,
                        to: displayDate) ?? displayDate
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13))
                        .foregroundColor(Color.nafTextGray)
                }
                Spacer()
                Text(monthTitle)
                    .font(.system(
                        size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "1B3A6B"))
                Spacer()
                Button {
                    displayDate = Calendar.current.date(
                        byAdding: .month,
                        value: 1,
                        to: displayDate) ?? displayDate
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundColor(Color.nafTextGray)
                }
            }

            HStack(spacing: 0) {
                ForEach(weekHeaders, id: \.self) { h in
                    Text(h)
                        .font(.system(
                            size: 11, weight: .medium))
                        .foregroundColor(Color.nafTextGray)
                        .frame(maxWidth: .infinity)
                }
            }

            ForEach(0..<grid.count, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(0..<7) { c in
                        let day = grid[r][c]
                        if day == 0 {
                            Color.clear
                                .frame(maxWidth: .infinity)
                                .frame(height: 34)
                        } else {
                            let isSel = selectedDates
                                .contains(day)
                            let isToday = day == todayDay
                            Button {
                                if isSel {
                                    selectedDates.remove(day)
                                } else {
                                    selectedDates.insert(day)
                                }
                            } label: {
                                Text("\(day)")
                                    .font(.system(
                                        size: 13,
                                        weight: isSel
                                        ? .bold : .regular))
                                    .foregroundColor(
                                        isSel ? .white
                                        : isToday
                                        ? Color(hex: "2D6DAB")
                                        : Color(hex: "1B3A6B"))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 34)
                                    .background(
                                        isSel
                                        ? Color(hex: "2D6DAB")
                                        : Color.clear)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(
                                        isToday && !isSel
                                        ? Color(hex: "2D6DAB")
                                        : Color.clear,
                                        lineWidth: 1.5))
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(Color(hex: "2D6DAB").opacity(0.3),
                    lineWidth: 1))
    }
}

// ═══════════════════════════════════════════════
// MARK: - Pending Requests
// ═══════════════════════════════════════════════
struct PendingRequestsSection: View {
    @Binding var requests: [PendingRequest]
    var pendingCount: Int {
        requests.filter { $0.isApproved == nil }.count
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(pendingCount) PENDING REQUESTS")
                .font(.system(size: 11, weight: .bold))
                .tracking(0.8)
                .foregroundColor(Color.nafTextGray)
                .padding(.horizontal, 4)
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
    var pillBg:  Color {
        request.isPositive
        ? Color(hex: "FFF3DC")
        : Color(hex: "FDEAEA")
    }
    var pillText: Color {
        request.isPositive
        ? Color(hex: "B87A00")
        : Color(hex: "C0392B")
    }
    var amtColor: Color {
        request.isPositive
        ? Color(hex: "2D7A4F")
        : Color(hex: "C0392B")
    }
    var amtText: String {
        request.isPositive
        ? "+\(Int(request.amount)) SAR"
        : "\(Int(request.amount)) SAR"
    }
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "EBF0F8"))
                        .frame(width: 40, height: 40)
                    Text(request.childInitial)
                        .font(.system(
                            size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "2D6DAB"))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(request.childName) \(request.action)")
                        .font(.system(
                            size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "1B3A6B"))
                    Text(request.time)
                        .font(.system(size: 12))
                        .foregroundColor(Color.nafTextGray)
                }
                Spacer()
                Text(amtText)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(amtColor)
            }
            Text(request.description)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(pillText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(pillBg)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            HStack(spacing: 10) {
                Button {
                    withAnimation { request.isApproved = true }
                    if let goalId = request.goalId {
                        Task {
                            // Update goal status
                            try? await supabase
                                .from("goals")
                                .update(["status": "approved"])
                                .eq("id", value: goalId.uuidString)
                                .execute()

                            // Get child_id from goal
                            struct GoalRow: Codable {
                                let child_id: String
                                let title: String
                            }
                            if let goal = try? await supabase
                                .from("goals")
                                .select("child_id, title")
                                .eq("id", value: goalId.uuidString)
                                .single()
                                .execute()
                                .value as GoalRow {

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
                                        child_id:  goal.child_id,
                                        title:     "🎉 Your goal '\(goal.title)' was approved!",
                                        meta:      "Parent approved",
                                        sf_symbol: "checkmark.circle.fill",
                                        jar_color: "green"))
                                    .execute()
                            }
                        }
                    }
                } label: {
                    Text("Approve")                        .font(.system(
                            size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(Color(hex: "2D7A4F"))
                        .clipShape(RoundedRectangle(
                            cornerRadius: 10))
                }
                Button {
                    withAnimation { request.isApproved = false }
                    if let goalId = request.goalId {
                        Task {
                            try? await supabase
                                .from("goals")
                                .update(["status": "rejected"])
                                .eq("id", value: goalId.uuidString)
                                .execute()

                            struct GoalRow: Codable {
                                let child_id: String
                                let title: String
                            }
                            if let goal = try? await supabase
                                .from("goals")
                                .select("child_id, title")
                                .eq("id", value: goalId.uuidString)
                                .single()
                                .execute()
                                .value as GoalRow {

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
                                        child_id:  goal.child_id,
                                        title:     "❌ Your goal '\(goal.title)' was rejected",
                                        meta:      "Parent rejected",
                                        sf_symbol: "xmark.circle.fill",
                                        jar_color: "red"))
                                    .execute()
                            }
                        }
                    }
                } label: {
                    Text("Decline")                        .font(.system(
                            size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(Color(hex: "8B1A1A"))
                        .clipShape(RoundedRectangle(
                            cornerRadius: 10))
                }
            }
        }
        .padding(14)
        .background(Color(hex: "F9FAFB"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// ═══════════════════════════════════════════════
// MARK: - Transaction History
// ═══════════════════════════════════════════════
struct TransactionHistorySection: View {
    @Binding var expanded: Bool
    let transactions: [TransferRecord]
    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35)) {
                    expanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "EBF0F8"))
                            .frame(width: 38, height: 38)
                        Image(systemName:
                            "list.bullet.rectangle")
                            .font(.system(size: 16))
                            .foregroundColor(
                                Color(hex: "2D6DAB"))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Transaction History")
                            .font(.system(
                                size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "1B3A6B"))
                        Text("All your transfers")
                            .font(.system(size: 12))
                            .foregroundColor(Color.nafTextGray)
                    }
                    Spacer()
                    Image(systemName: expanded
                          ? "chevron.up" : "chevron.down")
                        .font(.system(
                            size: 13, weight: .medium))
                        .foregroundColor(Color.nafTextGray)
                }
                .padding(14)
            }

            if expanded {
                Divider().padding(.horizontal, 14)
                if transactions.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName:
                            "arrow.left.arrow.right")
                            .font(.system(size: 28))
                            .foregroundColor(Color.nafTextGray)
                        Text("No transfers yet")
                            .font(.system(size: 14))
                            .foregroundColor(Color.nafTextGray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                } else {
                    VStack(spacing: 0) {
                        ForEach(
                            Array(transactions.enumerated()),
                            id: \.element.id
                        ) { idx, record in
                            HStack {
                                VStack(alignment: .leading,
                                       spacing: 3) {
                                    Text("\(record.type) → \(record.childName)")
                                        .font(.system(
                                            size: 14,
                                            weight: .medium))
                                        .foregroundColor(
                                            Color(hex: "1B3A6B"))
                                    Text(record.date)
                                        .font(.system(size: 12))
                                        .foregroundColor(
                                            Color.nafTextGray)
                                }
                                Spacer()
                                Text("-\(Int(record.amount)) SAR")
                                    .font(.system(
                                        size: 14,
                                        weight: .semibold))
                                    .foregroundColor(
                                        Color(hex: "C0392B"))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            if idx < transactions.count - 1 {
                                Divider()
                                    .padding(.horizontal, 14)
                            }
                        }
                    }
                }
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    TransfersView()
        .environmentObject(ParentViewModel())
        .environmentObject(AuthViewModel())
}
