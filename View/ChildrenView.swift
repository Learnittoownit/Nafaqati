import SwiftUI
import Supabase

struct ChildrenView: View {
    @EnvironmentObject var authVM:   AuthViewModel
    @EnvironmentObject var parentVM: ParentViewModel

    @State private var children: [ChildProfile] = []
    @State private var jarsByChild: [UUID: [Jar]] = [:]
    @State private var isLoading = false
    @State private var expandedChildId: UUID? = nil
    @State private var selectedChildForActivity: ChildProfile? = nil

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                Color(hex: "2D6DAB")
                    .frame(height: UIScreen.main.bounds.height * 0.38)
                Color(hex: "E8EDF2")
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header (same as Transfers) ────────
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Children")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text("Track your children's goals, jars and activity")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 24)

                // ── White card body ───────────────────
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {

                        if isLoading {
                            ProgressView()
                                .tint(Color(hex: "2D6DAB"))
                                .padding(.top, 60)
                                .frame(maxWidth: .infinity)

                        } else if children.isEmpty {
                            VStack(spacing: 14) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(Color(hex: "2D6DAB").opacity(0.4))
                                Text("No children added yet")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(hex: "2D6DAB").opacity(0.6))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)

                        } else {
                            ForEach(children) { child in
                                ChildCard(
                                    child: child,
                                    jars: jarsByChild[child.id] ?? [],
                                    sentBalance: parentVM.activity
                                        .filter { $0.title.contains("to \(child.name)") }
                                        .compactMap { item -> Double? in
                                            let parts = item.title.components(separatedBy: " ")
                                            if let idx = parts.firstIndex(of: "transferred"),
                                               idx + 1 < parts.count,
                                               let amt = Double(parts[idx + 1]) {
                                                return amt
                                            }
                                            return nil
                                        }
                                        .reduce(0, +),
                                    isExpanded: expandedChildId == child.id,
                                    onToggle: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                            expandedChildId = (expandedChildId == child.id) ? nil : child.id
                                        }
                                    },
                                    onRecentActivity: {
                                        selectedChildForActivity = child
                                    }
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 110)
                }
                .background(
                    Color(hex: "E8EDF2")
                        .cornerRadius(50, corners: [.topLeft, .topRight])
                )
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color(hex: "E8EDF2"))
        .task { await fetchData() }
        .sheet(item: $selectedChildForActivity) { child in
            RecentActivitySheet(child: child, jars: jarsByChild[child.id] ?? [])
        }
    }

    private func fetchData() async {
        guard let parentId = authVM.currentUserId else { return }
        isLoading = true
        do {
            let fetched: [ChildProfile] = try await supabase
                .from("child_profile")
                .select()
                .eq("parent_id", value: parentId.uuidString)
                .execute()
                .value
            await MainActor.run { children = fetched }

            for child in fetched {
                do {
                    let jars: [Jar] = try await supabase
                        .from("jars")
                        .select()
                        .eq("child_id", value: child.id.uuidString)
                        .execute()
                        .value
                    await MainActor.run { jarsByChild[child.id] = jars }
                } catch {
                    print("⚠️ jars error for \(child.name): \(error)")
                }
            }
        } catch {
            print("❌ ChildrenView fetchData: \(error)")
        }
        await MainActor.run { isLoading = false }
    }
}

// ═══════════════════════════════════════════════
// MARK: - ChildCard
// ═══════════════════════════════════════════════
struct ChildCard: View {
    let child: ChildProfile
    let jars: [Jar]
    let sentBalance: Double
    let isExpanded: Bool
    let onToggle: () -> Void
    let onRecentActivity: () -> Void
    var childPIN:       String { child.pin        ?? "" }
    var childInviteCode: String { child.inviteCode ?? "" }
    
    var savingBalance:   Double { jars.first(where: { $0.type == .saving   })?.balance ?? 0 }
    var givingBalance:   Double { jars.first(where: { $0.type == .giving   })?.balance ?? 0 }
    var spendingBalance: Double { jars.first(where: { $0.type == .spending })?.balance ?? 0 }
    var totalBalance:    Double { sentBalance > 0 ? sentBalance : (savingBalance + givingBalance + spendingBalance) }
    var savingPercent:   Double { guard totalBalance > 0 else { return 0 }; return min(savingBalance / totalBalance, 1.0) }
    var savingPercentInt: Int  { Int(savingPercent * 100) }
    var hasNoGoal: Bool        { totalBalance == 0 }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color.white).frame(width: 50, height: 50)
                            if let avatar = child.avatarUrl, !avatar.isEmpty {
                                Text(avatar).font(.system(size: 26))
                            } else {
                                Image(systemName: "person.fill").font(.system(size: 22)).foregroundColor(Color(hex: "2D6DAB"))
                            }
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(child.name).font(.system(size: 18, weight: .bold)).foregroundColor(Color(hex: "1B3A6B"))
                            Text("age : \(child.age)").font(.system(size: 13)).foregroundColor(Color(hex: "2D6DAB"))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Total balance").font(.system(size: 11)).foregroundColor(Color(hex: "2D6DAB"))
                            Text("\(Int(totalBalance)) SAR").font(.system(size: 20, weight: .bold)).foregroundColor(Color(hex: "1B3A6B"))
                        }
                    }

                    HStack(spacing: 8) {
                        Text("🎯").font(.system(size: 16))
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.55)).frame(height: 9)
                                RoundedRectangle(cornerRadius: 5).fill(Color(hex: "1B3A6B"))
                                    .frame(width: geo.size.width * CGFloat(savingPercent), height: 9)
                                    .animation(.easeInOut(duration: 0.5), value: savingPercent)
                            }
                        }
                        .frame(height: 9)
                        Text("\(savingPercentInt)%").font(.system(size: 13, weight: .semibold)).foregroundColor(Color(hex: "1B3A6B")).frame(minWidth: 34, alignment: .trailing)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down").font(.system(size: 12, weight: .semibold)).foregroundColor(Color(hex: "1B3A6B"))
                    }
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider().background(Color(hex: "B8CEE8")).padding(.horizontal, 14)
                VStack(spacing: 14) {
                    if hasNoGoal {
                        HStack(spacing: 8) {
                            Text("⚠️").font(.system(size: 14))
                            Text("No goal set yet, encourage \(child.name) to set one!")
                                .font(.system(size: 13, weight: .medium)).foregroundColor(Color(hex: "7A5C00"))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14).padding(.vertical, 12)
                        .background(Color(hex: "FFF3CC")).clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    HStack(spacing: 10) {
                        ChildJarPill(label: "Saving",   amount: savingBalance,   textColor: Color(hex: "8B5E00"), bgColor: Color(hex: "FEF0CC"))
                        ChildJarPill(label: "Giving",   amount: givingBalance,   textColor: Color(hex: "1E6B3C"), bgColor: Color(hex: "D6F0E2"))
                        ChildJarPill(label: "Spending", amount: spendingBalance, textColor: Color(hex: "9B2020"), bgColor: Color(hex: "FDDADA"))
                    }// PIN display
                    if !childInviteCode.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CHILD LOGIN CODE")
                                .font(.system(
                                    size: 10,
                                    weight: .bold,
                                    design: .rounded))
                                .foregroundColor(Color(hex: "2D6DAB"))
                                .tracking(1)

                            HStack(spacing: 8) {
                                ForEach(
                                    Array(childInviteCode.enumerated()),
                                    id: \.offset) { _, digit in
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(hex: "1B3A6B"))
                                            .frame(width: 36, height: 44)
                                        Text(String(digit))
                                            .font(.system(
                                                size: 20,
                                                weight: .bold,
                                                design: .rounded))
                                            .foregroundColor(.white)
                                    }
                                }

                                Spacer()

                                Button {
                                    UIPasteboard.general.string =
                                        childInviteCode
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.on.doc")
                                            .font(.system(size: 13))
                                        Text("Copy")
                                            .font(.system(
                                                size: 13,
                                                weight: .semibold,
                                                design: .rounded))
                                    }
                                    .foregroundColor(Color(hex: "2D6DAB"))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                }
                            }

                            Text("Share this code with \(child.name) so they can log in")
                                .font(.system(
                                    size: 11,
                                    design: .rounded))
                                .foregroundColor(Color(hex: "8A9BB0"))
                        }
                        .padding(14)
                        .background(Color(hex: "EBF4FF"))
                        .cornerRadius(12)
                    }
                    Button(action: onRecentActivity) {
                        Text("Recent Activity")
                            .font(.system(size: 15, weight: .bold)).foregroundColor(Color(hex: "1B3A6B"))
                            .frame(maxWidth: .infinity).frame(height: 48)
                            .background(Color.white).clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: Color.black.opacity(0.07), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(hex: "C8DCEF"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// ═══════════════════════════════════════════════
// MARK: - ChildJarPill
// ═══════════════════════════════════════════════
struct ChildJarPill: View {
    let label: String; let amount: Double; let textColor: Color; let bgColor: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(label).font(.system(size: 11, weight: .semibold)).foregroundColor(textColor)
            Text("\(Int(amount)) SAR").font(.system(size: 13, weight: .bold)).foregroundColor(textColor)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
        .background(bgColor).clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// ═══════════════════════════════════════════════
// MARK: - RecentActivitySheet
// ═══════════════════════════════════════════════
struct RecentActivitySheet: View {
    let child: ChildProfile
    let jars: [Jar]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule().fill(Color.nafTextGray.opacity(0.3)).frame(width: 40, height: 4).frame(maxWidth: .infinity).padding(.top, 12).padding(.bottom, 20)

            VStack(alignment: .leading, spacing: 4) {
                Text("RECENT ACTIVITY").font(.system(size: 11, weight: .bold)).foregroundColor(Color(hex: "2D6DAB")).tracking(1.2)
                Text(child.name).font(.system(size: 22, weight: .bold)).foregroundColor(Color(hex: "1B3A6B"))
            }
            .padding(.horizontal, 20).padding(.bottom, 16)

            Divider()

            HStack(spacing: 0) {
                ForEach([
                    ("Saving",   jars.first(where: { $0.type == .saving   })?.balance ?? 0, Color(hex: "F5A623")),
                    ("Giving",   jars.first(where: { $0.type == .giving   })?.balance ?? 0, Color(hex: "4CAF82")),
                    ("Spending", jars.first(where: { $0.type == .spending })?.balance ?? 0, Color(hex: "E05A5A"))
                ], id: \.0) { label, amount, color in
                    VStack(spacing: 4) {
                        Text(label).font(.system(size: 11)).foregroundColor(.nafTextGray)
                        Text("\(Int(amount)) SAR").font(.system(size: 15, weight: .bold)).foregroundColor(color)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    if label != "Spending" { Divider() }
                }
            }
            .background(Color(hex: "F5F8FF"))

            Divider()

            VStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath").font(.system(size: 36)).foregroundColor(Color(hex: "2D6DAB").opacity(0.3))
                Text("No recent activity yet").font(.system(size: 15, weight: .medium)).foregroundColor(.nafTextGray)
                Text("Activity will appear here once\n\(child.name) starts using the app.")
                    .font(.system(size: 13)).foregroundColor(.nafTextGray.opacity(0.8)).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity).padding(.top, 50)

            Spacer()
        }
        .background(Color.white)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}

#Preview {
    ChildrenView()
        .environmentObject(AuthViewModel())
        .environmentObject(ParentViewModel())
}
