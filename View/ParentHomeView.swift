import SwiftUI

struct ParentHomeView: View {

    @EnvironmentObject var parentVM: ParentViewModel

    @State private var showAddMoneySheet = false
    @State private var addMoneyAmount    = ""
    @State private var showFullHistory   = false

    // greeting based on time
    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "good morning" }
        if h < 17 { return "good afternoon" }
        return "good evening"
    }

    // today items only
    private var todayActivity: [ActivityItem] {
        parentVM.activity.filter { $0.isToday }
    }

    // older items
    private var olderActivity: [ActivityItem] {
        parentVM.activity.filter { !$0.isToday }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {

                // ── HEADER ────────────────────────────
                ZStack(alignment: .bottom) {
                    Color(hex: "2D6DAB")
                        .frame(maxWidth: .infinity)

                    VStack(spacing: 0) {
                        // top row
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 46, height: 46)
                                Image(systemName: "person.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Hi, \(parentVM.parentName)")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.white)
                                Text(greeting)
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.65))
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 56)

                        Spacer().frame(height: 28)

                        // balance
                        Text("MY BALANCE")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1.5)
                            .foregroundColor(Color(hex: "F5A623"))

                        Text("\(Int(parentVM.balance).formatted()) SAR")
                            .font(.system(size: 42, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.top, 4)

                        // add money button
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
                        .padding(.bottom, 40)
                    }
                }

                // ── WHITE CARD BODY ───────────────────
                VStack(spacing: 14) {

                    // STATS
                    HStack(spacing: 8) {
                        StatCard(icon: "person.2.fill",  label: "Active Children", value: "\(parentVM.activeChildren)", sub: "children")
                        StatCard(icon: "chart.line.uptrend.xyaxis", label: "Money Sent", value: "\(Int(parentVM.moneySent)) SAR", sub: "")
                        StatCard(icon: "scope",          label: "Active Goals",    value: "\(parentVM.activeGoals)",    sub: "Goals")
                    }

                    // REMINDER — only shows if within 2 days
                    if let reminderText = parentVM.reminderText {
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
                                Text(reminderText)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "E05555"))
                            }
                            Spacer()
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

                        // header row
                        HStack {
                            Text("THIS WEEK")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1)
                                .foregroundColor(Color.nafTextGray)
                            Spacer()
                            // show + only if there are older items
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

                        // empty state
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
                            // TODAY rows — always visible
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

                            // OLDER rows — shown when + tapped
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
                .padding(.top, -20)
                .padding(.bottom, 100)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(hex: "E8EDF2"))
                )
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color(hex: "E8EDF2"))

        // ── ADD MONEY SHEET ───────────────────
        .sheet(isPresented: $showAddMoneySheet) {
            AddMoneySheet(amount: $addMoneyAmount) {
                if let amt = Double(addMoneyAmount), amt > 0 {
                    parentVM.addToBalance(amt)
                    addMoneyAmount = ""
                    showAddMoneySheet = false
                }
            }
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Stat Card
// ─────────────────────────────────────────────
struct StatCard: View {
    let icon:  String
    let label: String
    let value: String
    let sub:   String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Text(value)
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(.white)
            if !sub.isEmpty {
                Text(sub)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(hex: "1B3A6B").opacity(0.55))
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
                    .background(canAdd ? Color(hex: "1B3A6B") : Color.nafTextGray)
                    .cornerRadius(27)
            }
            .disabled(!canAdd)
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
        .background(Color.white)
    }
}