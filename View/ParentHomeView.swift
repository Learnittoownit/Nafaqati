import SwiftUI

struct ParentHomeView: View {

    @EnvironmentObject var parentVM: ParentViewModel

    @State private var showAddMoneySheet = false
    @State private var addMoneyAmount    = ""
    @State private var showFullHistory   = false

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "good morning" }
        if h < 17 { return "good afternoon" }
        return "good evening"
    }

    private var todayActivity: [ActivityItem] {
        parentVM.activity.filter { $0.isToday }
    }

    private var olderActivity: [ActivityItem] {
        parentVM.activity.filter { !$0.isToday }
    }

    var body: some View {
        ZStack(alignment: .top) {

            Color(hex: "2D6DAB")
                .ignoresSafeArea(edges: .top)
                .frame(height: 360)
                .frame(maxHeight: .infinity, alignment: .top)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── HEADER CONTENT ────────────────
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 52, height: 52)
                                Text(parentVM.parentAvatar.isEmpty ? "🧑🏽" : parentVM.parentAvatar)
                                    .font(.system(size: 30))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Hi, \(parentVM.parentName.isEmpty ? "there" : parentVM.parentName)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                Text(greeting)
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.65))
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 60)

                        Spacer().frame(height: 24)

                        Text("MY BALANCE")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1.5)
                            .foregroundColor(Color(hex: "FFD580"))

                        Text("\(Int(parentVM.balance).formatted()) SAR")
                            .font(.system(size: 42, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.top, 4)

                        Button {
                            showAddMoneySheet = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Add Money")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .foregroundColor(Color(hex: "1B3A6B"))
                            .padding(.horizontal, 28)
                            .padding(.vertical, 13)
                            .background(Color.white)
                            .clipShape(Capsule())
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                    }

                    // ── WHITE ROUNDED CARD BODY ───────
                    VStack(spacing: 14) {

                        // STATS
                        HStack(spacing: 10) {
                            StatTile(icon: "person.2.fill", label: "Active Children",
                                     value: "\(parentVM.activeChildren)", sub: "children")
                            StatTile(icon: "chart.line.uptrend.xyaxis", label: "Money Sent",
                                     value: "\(Int(parentVM.moneySent))", sub: "SAR")
                            StatTile(icon: "scope", label: "Active Goals",
                                     value: "\(parentVM.activeGoals)", sub: "Goals")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color(hex: "2D6DAB"))
                        .cornerRadius(18)

                        // ── REMINDERS (one banner per child) ──
                        ForEach(parentVM.activeSchedules) { schedule in
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: "C0392B"))
                                    .frame(width: 38, height: 38)
                                    .overlay(
                                        Image(systemName: "bell.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                    )
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Allowance Reminder")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Color(hex: "C0392B"))
                                    Text(parentVM.reminderText(for: schedule))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "E05555"))
                                }
                                Spacer()
                                // ── Remove button ──
                                Button {
                                    withAnimation {
                                        parentVM.removeReminder(for: schedule.childName)
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color(hex: "C0392B").opacity(0.5))
                                }
                            }
                            .padding(14)
                            .background(Color(hex: "FFF0EE"))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(hex: "E05555").opacity(0.4), lineWidth: 1)
                            )
                        }

                        // ACTIVITY CARD
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text("THIS WEEK")
                                    .font(.system(size: 11, weight: .bold))
                                    .tracking(1)
                                    .foregroundColor(Color.nafTextGray)
                                Spacer()
                                if !olderActivity.isEmpty {
                                    Button {
                                        withAnimation(.spring(response: 0.35)) {
                                            showFullHistory.toggle()
                                        }
                                    } label: {
                                        Image(systemName: showFullHistory ? "minus" : "plus")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(Color(hex: "1B3A6B"))
                                            .frame(width: 26, height: 26)
                                            .background(Color(hex: "DDE3EB"))
                                            .clipShape(Circle())
                                    }
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.top, 14)
                            .padding(.bottom, 8)

                            if parentVM.activity.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "tray")
                                        .font(.system(size: 28))
                                        .foregroundColor(Color.nafTextGray)
                                    Text("No activity yet")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.nafTextGray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 28)
                            } else {
                                if todayActivity.isEmpty {
                                    Text("No activity today yet")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color.nafTextGray)
                                        .padding(.horizontal, 14)
                                        .padding(.bottom, 12)
                                } else {
                                    ForEach(todayActivity) { item in
                                        ActivityRow(item: item)
                                    }
                                }

                                if showFullHistory && !olderActivity.isEmpty {
                                    Divider().padding(.horizontal, 14)
                                    Text("EARLIER")
                                        .font(.system(size: 10, weight: .bold))
                                        .tracking(1)
                                        .foregroundColor(Color.nafTextGray)
                                        .padding(.horizontal, 14)
                                        .padding(.top, 10)
                                        .padding(.bottom, 4)
                                    ForEach(olderActivity) { item in
                                        ActivityRow(item: item)
                                    }
                                }
                            }

                            Spacer().frame(height: 8)
                        }
                        .background(Color.white)
                        .cornerRadius(18)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
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
        .sheet(isPresented: $showAddMoneySheet) {
            AddMoneySheet(amount: $addMoneyAmount) {
                if let amt = Double(addMoneyAmount), amt > 0 {
                    Task {
                        await parentVM.addToBalance(amt)
                        addMoneyAmount    = ""
                        showAddMoneySheet = false
                    }
                }
            }
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Rounded corners helper
// ─────────────────────────────────────────────
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// ─────────────────────────────────────────────
// MARK: - Stat Tile
// ─────────────────────────────────────────────
struct StatTile: View {
    let icon:  String
    let label: String
    let value: String
    let sub:   String

    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            Text(value)
                .font(.system(size: 21, weight: .heavy))
                .foregroundColor(.white)
            if !sub.isEmpty {
                Text(sub)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.55))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 85, maxHeight: 85, alignment: .center)
        .padding(10)
        .background(Color.white.opacity(0.22))
        .cornerRadius(14)
    }
}

// ─────────────────────────────────────────────
// MARK: - Activity Row
// ─────────────────────────────────────────────
struct ActivityRow: View {
    let item: ActivityItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(item.isToday ? Color(hex: "2D6DAB") : Color(hex: "DDE3EB"))
                .frame(width: 9, height: 9)
                .padding(.top, 4)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "1B3A6B"))
                Text(item.meta)
                    .font(.system(size: 11))
                    .foregroundColor(Color.nafTextGray)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }
}

// ─────────────────────────────────────────────
// MARK: - Add Money Sheet
// ─────────────────────────────────────────────
struct AddMoneySheet: View {
    @Binding var amount: String
    let onAdd: () -> Void

    var canAdd: Bool {
        if let val = Double(amount) { return val > 0 }
        return false
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 0) {
                Text("Add to balance")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color(hex: "1B3A6B"))
                    .padding(.top, 20)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Amount (SAR)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.nafTextGray)

                    TextField("Enter amount", text: $amount)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "1B3A6B"))
                        .multilineTextAlignment(.center)
                        .padding(16)
                        .background(Color(hex: "E8EDF2"))
                        .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Button(action: onAdd) {
                    Text("Add")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color(hex: "1B3A6B"))
                        .cornerRadius(27)
                }
                .disabled(!canAdd)
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
        }
    }
}
