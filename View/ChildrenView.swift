// ChildrenView.swift
// Nafaqati
//
// The Children tab — parent sees all their children, each child's
// jar balances, goal progress, and can tap "Recent Activity" to see
// that child's latest transactions.
//
// Data flow:
//   • Children  → fetched from Supabase "child_profile" table
//   • Jars      → fetched from Supabase "jars" table per child
//   • Activity  → empty state for now (Phase 2: fetch from transactions table)

import SwiftUI
import Supabase

// ═══════════════════════════════════════════════
// MARK: - ChildrenView
// ═══════════════════════════════════════════════

struct ChildrenView: View {
    @EnvironmentObject var authVM:    AuthViewModel
    @EnvironmentObject var parentVM:  ParentViewModel

    @State private var children: [ChildProfile] = []
    @State private var jarsByChild: [UUID: [Jar]] = [:]
    @State private var isLoading = false
    @State private var expandedChildId: UUID? = nil
    @State private var selectedChildForActivity: ChildProfile? = nil

    var body: some View {
        ZStack(alignment: .top) {

            // ── Blue background behind header ─────────────────────
            Color(hex: "2D6DAB").ignoresSafeArea(edges: .top)

            VStack(spacing: 0) {

                // ── Header ────────────────────────────────────────
                Text("My Children")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    .padding(.bottom, 28)

                // ── Light card (rounded top corners, fills screen) ─
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
                    .padding(.bottom, 40)
                }
                .background(Color(hex: "EEF3FA"))
                .cornerRadius(30, corners: [.topLeft, .topRight])
            }
        }
        .task {
            await fetchData()
        }
        .sheet(item: $selectedChildForActivity) { child in
            RecentActivitySheet(
                child: child,
                jars: jarsByChild[child.id] ?? []
            )
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Fetch Data
    // ─────────────────────────────────────────────────────────────────

    private func fetchData() async {
        guard let parentId = authVM.currentUserId else { return }
        isLoading = true

        do {
            // 1. Fetch all children for this parent
            let fetchedChildren: [ChildProfile] = try await supabase
                .from("child_profile")
                .select()
                .eq("parent_id", value: parentId.uuidString)
                .execute()
                .value

            await MainActor.run { children = fetchedChildren }

            // 2. Fetch jars for each child
            for child in fetchedChildren {
                do {
                    let jars: [Jar] = try await supabase
                        .from("jars")
                        .select()
                        .eq("child_id", value: child.id.uuidString)
                        .execute()
                        .value
                    await MainActor.run { jarsByChild[child.id] = jars }
                } catch {
                    print("⚠️ Could not load jars for \(child.name): \(error)")
                }
            }

        } catch {
            print("❌ ChildrenView fetchData error: \(error)")
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
    let sentBalance: Double          // total SAR the parent sent to this child
    let isExpanded: Bool
    let onToggle: () -> Void
    let onRecentActivity: () -> Void

    // ── Computed balances ─────────────────────
    var savingBalance:  Double { jars.first(where: { $0.type == .saving  })?.balance ?? 0 }
    var givingBalance:  Double { jars.first(where: { $0.type == .giving  })?.balance ?? 0 }
    var spendingBalance: Double { jars.first(where: { $0.type == .spending })?.balance ?? 0 }
    // Total balance = what the parent sent (tracks in-session transfers) or jar sum from Supabase
    var totalBalance:   Double { sentBalance > 0 ? sentBalance : (savingBalance + givingBalance + spendingBalance) }

    // Saving progress toward goal (shown as % of total, or 0 if no data)
    var savingPercent: Double {
        guard totalBalance > 0 else { return 0 }
        return min(savingBalance / totalBalance, 1.0)
    }
    var savingPercentInt: Int { Int(savingPercent * 100) }

    // No goal = saving jar is 0 and all balances are 0
    var hasNoGoal: Bool { totalBalance == 0 }

    var body: some View {
        VStack(spacing: 0) {

            // ── Collapsed header (always visible) ─────────────────
            Button(action: onToggle) {
                VStack(spacing: 14) {

                    // Name + income row
                    HStack(spacing: 12) {
                        // Avatar circle
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 50, height: 50)
                            Image(systemName: "person.fill")
                                .font(.system(size: 22))
                                .foregroundColor(Color(hex: "2D6DAB"))
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(child.name)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color(hex: "1B3A6B"))
                            Text("age : \(child.age)")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "2D6DAB"))
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Total balance")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "2D6DAB"))
                            Text("\(Int(totalBalance)) SAR")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color(hex: "1B3A6B"))
                        }
                    }

                    // Progress bar row
                    HStack(spacing: 8) {
                        // Goal icon (use saving jar color icon)
                        Text("🎯")
                            .font(.system(size: 16))

                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color.white.opacity(0.55))
                                    .frame(height: 9)
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color(hex: "1B3A6B"))
                                    .frame(width: geo.size.width * CGFloat(savingPercent), height: 9)
                                    .animation(.easeInOut(duration: 0.5), value: savingPercent)
                            }
                        }
                        .frame(height: 9)

                        Text("\(savingPercentInt)%")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "1B3A6B"))
                            .frame(minWidth: 34, alignment: .trailing)

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "1B3A6B"))
                    }
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            // ── Expanded details ──────────────────────────────────
            if isExpanded {
                Divider()
                    .background(Color(hex: "B8CEE8"))
                    .padding(.horizontal, 14)

                VStack(spacing: 14) {

                    // No-goal warning banner
                    if hasNoGoal {
                        HStack(spacing: 8) {
                            Text("⚠️")
                                .font(.system(size: 14))
                            Text("No goal set yet, encourage \(child.name) to set one!")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "7A5C00"))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color(hex: "FFF3CC"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Jar pills
                    HStack(spacing: 10) {
                        ChildJarPill(
                            label: "Saving",
                            amount: savingBalance,
                            textColor: Color(hex: "8B5E00"),
                            bgColor: Color(hex: "FEF0CC")
                        )
                        ChildJarPill(
                            label: "Giving",
                            amount: givingBalance,
                            textColor: Color(hex: "1E6B3C"),
                            bgColor: Color(hex: "D6F0E2")
                        )
                        ChildJarPill(
                            label: "Spending",
                            amount: spendingBalance,
                            textColor: Color(hex: "9B2020"),
                            bgColor: Color(hex: "FDDADA")
                        )
                    }

                    // Recent Activity button — matches design (white pill, blue text)
                    Button(action: onRecentActivity) {
                        Text("Recent Activity")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "1B3A6B"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: Color.black.opacity(0.07), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(hex: "C8DCEF"))  // light blue card
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// ═══════════════════════════════════════════════
// MARK: - ChildJarPill
// ═══════════════════════════════════════════════

struct ChildJarPill: View {
    let label: String
    let amount: Double
    let textColor: Color
    let bgColor: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(textColor)
            Text("\(Int(amount)) SAR")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(textColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(bgColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// ═══════════════════════════════════════════════
// MARK: - RecentActivitySheet
// ═══════════════════════════════════════════════
// Shows the child's recent transactions.
// Phase 2: fetch from Supabase transactions table.
// For now: empty state.

struct RecentActivitySheet: View {
    let child: ChildProfile
    let jars: [Jar]

    // Phase 2: replace with real fetched transactions
    // struct ChildActivityItem: Identifiable { ... }
    // @State private var activityItems: [ChildActivityItem] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Drag handle
            Capsule()
                .fill(Color.nafTextGray.opacity(0.3))
                .frame(width: 40, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.bottom, 20)

            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("RECENT ACTIVITY")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "2D6DAB"))
                    .tracking(1.2)

                Text(child.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: "1B3A6B"))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            Divider()

            // ── Jar summary strip ─────────────────────────────────
            HStack(spacing: 0) {
                ForEach([
                    ("Saving",   jars.first(where: { $0.type == .saving   })?.balance ?? 0, Color(hex: "F5A623")),
                    ("Giving",   jars.first(where: { $0.type == .giving   })?.balance ?? 0, Color(hex: "4CAF82")),
                    ("Spending", jars.first(where: { $0.type == .spending })?.balance ?? 0, Color(hex: "E05A5A"))
                ], id: \.0) { label, amount, color in
                    VStack(spacing: 4) {
                        Text(label)
                            .font(.system(size: 11))
                            .foregroundColor(.nafTextGray)
                        Text("\(Int(amount)) SAR")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(color)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    if label != "Spending" {
                        Divider()
                    }
                }
            }
            .background(Color(hex: "F5F8FF"))

            Divider()

            // ── Empty state (Phase 2: replace with real list) ─────
            VStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 36))
                    .foregroundColor(Color(hex: "2D6DAB").opacity(0.3))
                Text("No recent activity yet")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.nafTextGray)
                Text("Activity will appear here once\n\(child.name) starts using the app.")
                    .font(.system(size: 13))
                    .foregroundColor(.nafTextGray.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 50)

            Spacer()
        }
        .background(Color.white)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden) // we drew our own handle
    }
}

// ═══════════════════════════════════════════════
// MARK: - Preview
// ═══════════════════════════════════════════════

#Preview {
    ChildrenView()
        .environmentObject(AuthViewModel())
        .environmentObject(ParentViewModel())
}

