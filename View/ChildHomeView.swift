import SwiftUI
import Supabase

struct ChildHomeView: View {

    @Binding var goals:    [Goal]
    @Binding var activity: [ChildActivityItem]

    let childName = UserDefaults.standard.string(
        forKey: "childName") ?? "User"
    let avatar = UserDefaults.standard.string(
        forKey: "childAvatar") ?? "🦁"

    @State var savingBal:   Double = 0.0
    @State var givingBal:   Double = 0.0
    @State var spendingBal: Double = 0.0

    let jarWidth:  CGFloat = 100
    let jarHeight: CGFloat = 112

    var activeGoal: Goal? {
        goals.first { $0.status == "approved" && !$0.isAchieved }
    }
    var totalBalance: Double { savingBal + givingBal + spendingBal }

    var greetingText: String {
        let hour = Calendar.current.component(
            .hour, from: Date())
        let day = Calendar.current.component(
            .weekday, from: Date())
        if day == 6 { return "Happy Friday 🌟" }
        switch hour {
        case 5..<12:  return "Good morning ☀️"
        case 12..<17: return "Good afternoon 👋"
        case 17..<21: return "Good evening 🌙"
        default:      return "Good night ⭐"
        }
    }

    var levelLabel: String {
        switch totalBalance {
        case 0..<50:    return "💰 Beginner Saver"
        case 50..<150:  return "⭐ Smart Saver"
        case 150..<300: return "🏆 Super Saver"
        default:        return "👑 Money Master"
        }
    }

    var motivationText: String {
        if let goal = activeGoal {
            let remaining = goal.target - goal.saved
            if goal.percent >= 90 {
                return "🎉 Almost there! Just \(Int(remaining)) SAR to go!"
            } else if goal.percent >= 50 {
                return "🔥 Halfway to your \(goal.name)!"
            } else {
                return "💪 Keep saving for your \(goal.name)!"
            }
        }
        return ""
    }

    func timeAgo(_ date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        switch seconds {
        case 0..<60:    return "Just now"
        case 60..<3600:
            let mins = seconds / 60
            return "\(mins) min\(mins > 1 ? "s" : "") ago"
        case 3600..<86400:
            let hours = seconds / 3600
            return "\(hours) hour\(hours > 1 ? "s" : "") ago"
        case 86400..<604800:
            let days = seconds / 86400
            return "\(days) day\(days > 1 ? "s" : "") ago"
        default:
            let weeks = seconds / 604800
            return "\(weeks) week\(weeks > 1 ? "s" : "") ago"
        }
    }

    var body: some View {
        ZStack(alignment: .top) {

            VStack(spacing: 0) {
                Color(hex: "1B3A6B").frame(height: 420)
                Color(hex: "EEF2F8")
            }
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── BLUE HEADER ──────────────
                    VStack(spacing: 0) {

                        Spacer().frame(height: 56)

                        HStack(alignment: .top) {
                            VStack(alignment: .leading,
                                   spacing: 4) {
                                Text(greetingText)
                                    .font(.system(
                                        size: 14,
                                        design: .rounded))
                                    .foregroundColor(
                                        .white.opacity(0.85))
                                Text(levelLabel)
                                    .font(.system(
                                        size: 11,
                                        weight: .semibold,
                                        design: .rounded))
                                    .foregroundColor(
                                        Color(hex: "FAC775"))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        Color.white.opacity(0.15))
                                    .cornerRadius(10)
                            }
                            Spacer()
                            // ── Sign out button ──
                            SignOutButton()
                        }
                        .padding(.horizontal, 24)

                        Spacer().frame(height: 20)

                        ZStack {
                            Circle()
                                .stroke(
                                    .white.opacity(0.35),
                                    lineWidth: 2)
                                .frame(width: 88, height: 88)
                            Circle()
                                .fill(.white.opacity(0.08))
                                .frame(width: 84, height: 84)
                            ChildAvatarView(avatar: avatar, size: 84)
                        }

                        Spacer().frame(height: 10)

                        Text(childName)
                            .font(.system(
                                size: 22,
                                weight: .bold,
                                design: .rounded))
                            .foregroundColor(.white)

                        Spacer().frame(height: 20)

                        Text("TOTAL BALANCE")
                            .font(.system(
                                size: 11,
                                weight: .semibold,
                                design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .tracking(1.5)

                        Spacer().frame(height: 4)

                        Text("\(Int(totalBalance)) SAR")
                            .font(.system(
                                size: 42,
                                weight: .bold,
                                design: .rounded))
                            .foregroundColor(.white)

                        if !motivationText.isEmpty {
                            Spacer().frame(height: 8)
                            Text(motivationText)
                                .font(.system(
                                    size: 13,
                                    design: .rounded))
                                .foregroundColor(
                                    .white.opacity(0.75))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }

                        Spacer().frame(height: 36)
                    }
                    .frame(maxWidth: .infinity)

                    // ── WHITE CARD ───────────────
                    VStack(alignment: .leading, spacing: 24) {

                        // MY JARS
                        VStack(alignment: .leading,
                               spacing: 14) {
                            Text("MY JARS")
                                .font(.system(
                                    size: 12,
                                    weight: .semibold,
                                    design: .rounded))
                                .foregroundColor(
                                    Color(hex: "8A9BB0"))
                                .tracking(1.2)

                            HStack(spacing: 0) {
                                JarCardHome(
                                    imageName: jarImage(
                                        amount: savingBal,
                                        color: "yellow"),
                                    label: "Saving",
                                    amount: savingBal,
                                    borderColor: Color(
                                        hex: "E8A020"),
                                    jarWidth: jarWidth,
                                    jarHeight: jarHeight)
                                JarCardHome(
                                    imageName: jarImage(
                                        amount: givingBal,
                                        color: "green"),
                                    label: "Giving",
                                    amount: givingBal,
                                    borderColor: Color(
                                        hex: "4CAF50"),
                                    jarWidth: jarWidth,
                                    jarHeight: jarHeight)
                                JarCardHome(
                                    imageName: jarImage(
                                        amount: spendingBal,
                                        color: "red"),
                                    label: "Spending",
                                    amount: spendingBal,
                                    borderColor: Color(
                                        hex: "E05555"),
                                    jarWidth: jarWidth,
                                    jarHeight: jarHeight)
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(18)
                        }

                        // MY GOAL
                        VStack(alignment: .leading,
                               spacing: 14) {
                            Text("MY GOAL")
                                .font(.system(
                                    size: 12,
                                    weight: .semibold,
                                    design: .rounded))
                                .foregroundColor(
                                    Color(hex: "8A9BB0"))
                                .tracking(1.2)

                            if let goal = activeGoal {
                                VStack(alignment: .leading,
                                       spacing: 12) {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            RoundedRectangle(
                                                cornerRadius: 10)
                                                .fill(.white
                                                    .opacity(0.15))
                                                .frame(
                                                    width: 52,
                                                    height: 52)
                                            GoalIconView(
                                                icon: goal.icon,
                                                size: 28)
                                        }
                                        VStack(
                                            alignment: .leading,
                                            spacing: 3) {
                                            Text(goal.name)
                                                .font(.system(
                                                    size: 16,
                                                    weight: .bold,
                                                    design:
                                                        .rounded))
                                                .foregroundColor(
                                                    .white)
                                            Text("Goal: \(Int(goal.target)) SAR")
                                                .font(.system(
                                                    size: 12,
                                                    design:
                                                        .rounded))
                                                .foregroundColor(
                                                    .white.opacity(
                                                        0.65))
                                        }
                                        Spacer()
                                        Text("\(goal.percent)%")
                                            .font(.system(
                                                size: 14,
                                                weight: .bold,
                                                design: .rounded))
                                            .foregroundColor(
                                                Color(hex: "FAC775"))
                                            .padding(
                                                .horizontal, 10)
                                            .padding(
                                                .vertical, 5)
                                            .background(
                                                Color.white
                                                    .opacity(0.15))
                                            .cornerRadius(10)
                                    }

                                    GeometryReader { geo in
                                        ZStack(
                                            alignment: .leading) {
                                            RoundedRectangle(
                                                cornerRadius: 4)
                                                .fill(.white
                                                    .opacity(0.2))
                                                .frame(height: 8)
                                            RoundedRectangle(
                                                cornerRadius: 4)
                                                .fill(
                                                    goal.percent
                                                    >= 90
                                                    ? Color(hex:
                                                        "4CAF50")
                                                    : .white)
                                                .frame(
                                                    width: geo
                                                        .size.width
                                                    * goal.progress,
                                                    height: 8)
                                        }
                                    }
                                    .frame(height: 8)

                                    HStack {
                                        Text("\(Int(goal.saved)) SAR saved")
                                            .font(.system(
                                                size: 12,
                                                design: .rounded))
                                            .foregroundColor(
                                                .white.opacity(
                                                    0.65))
                                        Spacer()
                                        Text("\(Int(goal.target - goal.saved)) SAR to go!")
                                            .font(.system(
                                                size: 12,
                                                design: .rounded))
                                            .foregroundColor(
                                                .white.opacity(
                                                    0.65))
                                    }
                                }
                                .padding(18)
                                .background(Color(hex: "152D56"))
                                .cornerRadius(18)

                            } else {
                                VStack(spacing: 10) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(
                                                hex: "E8EDF5"))
                                            .frame(
                                                width: 64,
                                                height: 64)
                                        Image(systemName: "target")
                                            .font(.system(
                                                size: 28,
                                                weight: .medium))
                                            .foregroundColor(
                                                Color(hex: "185FA5"))
                                    }
                                    Text("No goal yet!")
                                        .font(.system(
                                            size: 15,
                                            weight: .semibold,
                                            design: .rounded))
                                        .foregroundColor(
                                            Color(hex: "1B3A6B"))
                                    Text("Tap Goals tab to set\nyour first saving goal 🚀")
                                        .font(.system(
                                            size: 12,
                                            design: .rounded))
                                        .foregroundColor(
                                            Color(hex: "8A9BB0"))
                                        .multilineTextAlignment(
                                            .center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 28)
                                .background(Color.white)
                                .cornerRadius(18)
                            }
                        }

                        // RECENT ACTIVITY
                        VStack(alignment: .leading,
                               spacing: 14) {
                            Text("RECENT ACTIVITY")
                                .font(.system(
                                    size: 12,
                                    weight: .semibold,
                                    design: .rounded))
                                .foregroundColor(
                                    Color(hex: "8A9BB0"))
                                .tracking(1.2)

                            if activity.isEmpty {
                                VStack(spacing: 10) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(
                                                hex: "E8EDF5"))
                                            .frame(
                                                width: 64,
                                                height: 64)
                                        Image(systemName:
                                            "sparkles")
                                            .font(.system(
                                                size: 28,
                                                weight: .medium))
                                            .foregroundColor(
                                                Color(hex:
                                                    "185FA5"))
                                    }
                                    Text("No activity yet!")
                                        .font(.system(
                                            size: 15,
                                            weight: .semibold,
                                            design: .rounded))
                                        .foregroundColor(
                                            Color(hex: "1B3A6B"))
                                    Text("Transactions will appear here once\nyour parent sends your first allowance 🎁")
                                        .font(.system(
                                            size: 12,
                                            design: .rounded))
                                        .foregroundColor(
                                            Color(hex: "8A9BB0"))
                                        .multilineTextAlignment(
                                            .center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 28)
                                .background(Color.white)
                                .cornerRadius(18)

                            } else {
                                VStack(spacing: 0) {
                                    ForEach(activity) { item in
                                        HStack(spacing: 14) {
                                            ZStack {
                                                RoundedRectangle(
                                                    cornerRadius:
                                                        10)
                                                    .fill(iconBg(
                                                        item
                                                        .jarColor))
                                                    .frame(
                                                        width: 40,
                                                        height: 40)
                                                Image(systemName:
                                                    item.sfSymbol)
                                                    .font(.system(
                                                        size: 17,
                                                        weight:
                                                            .medium))
                                                    .foregroundColor(
                                                        iconColor(
                                                            item
                                                            .jarColor))
                                            }
                                            VStack(
                                                alignment:
                                                    .leading,
                                                spacing: 3) {
                                                Text(item.name)
                                                    .font(.system(
                                                        size: 14,
                                                        weight:
                                                            .medium,
                                                        design:
                                                            .rounded))
                                                    .foregroundColor(
                                                        Color(hex:
                                                            "1B3A6B"))
                                                    .fixedSize(
                                                        horizontal:
                                                            false,
                                                        vertical:
                                                            true)
                                                Text(timeAgo(
                                                    item.timestamp))
                                                    .font(.system(
                                                        size: 12,
                                                        design:
                                                            .rounded))
                                                    .foregroundColor(
                                                        Color(hex:
                                                            "8A9BB0"))
                                            }
                                            Spacer()
                                            if item.amount != 0 {
                                                Text(item.amount
                                                     > 0
                                                     ? "+\(Int(item.amount)) SAR"
                                                     : "\(Int(item.amount)) SAR")
                                                    .font(.system(
                                                        size: 14,
                                                        weight:
                                                            .semibold,
                                                        design:
                                                            .rounded))
                                                    .foregroundColor(
                                                        item.amount
                                                        > 0
                                                        ? Color(
                                                            hex:
                                                            "2E7D32")
                                                        : Color(
                                                            hex:
                                                            "C62828"))
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)

                                        // Voice note player
                                        if let vUrl = item.voiceNoteUrl,
                                           !vUrl.isEmpty {
                                            VoiceNotePlayerButton(url: vUrl)
                                                .padding(.horizontal, 16)
                                                .padding(.bottom, 12)
                                        }

                                        if item.id !=
                                            activity.last?.id {
                                            Divider()
                                                .padding(
                                                    .leading, 70)
                                        }
                                    }
                                }
                                .background(Color.white)
                                .cornerRadius(18)
                                .shadow(
                                    color: Color.black
                                        .opacity(0.05),
                                    radius: 8, x: 0, y: 2)
                            }
                        }

                        Spacer().frame(height: 20)
                    }
                    .padding(20)
                    .background(Color(hex: "EEF2F8"))
                    .clipShape(RoundedCorner(
                        radius: 28,
                        corners: [.topLeft, .topRight]))
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .onAppear {
            Task {
                await fetchJarBalances()
                await fetchRecentActivity()
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIApplication.willEnterForegroundNotification)
        ) { _ in
            Task {
                await fetchJarBalances()
                await fetchRecentActivity()
            }
        }
    }

    // ── Fetch jar balances from Supabase ──
    func fetchJarBalances() async {
        guard let childIdStr = UserDefaults.standard
            .string(forKey: "childId"),
              let childId = UUID(uuidString: childIdStr)
        else { return }

        do {
            let jars: [Jar] = try await supabase
                .from("jars")
                .select()
                .eq("child_id", value: childId.uuidString)
                .execute()
                .value

            await MainActor.run {
                for jar in jars {
                    switch jar.type {
                    case .saving:   savingBal   = jar.balance
                    case .spending: spendingBal = jar.balance
                    case .giving:   givingBal   = jar.balance
                    }
                }
            }
        } catch {
            print("❌ fetchJarBalances: \(error)")
        }
    }

    // ── Fetch recent activity from Supabase ──
    func fetchRecentActivity() async {
        guard let childIdStr = UserDefaults.standard
            .string(forKey: "childId"),
              let childId = UUID(uuidString: childIdStr)
        else { return }

        struct ChildActivityRow: Codable, Identifiable {
            let id:           UUID
            let title:        String
            let sfSymbol:     String?
            let jarColor:     String?
            let amount:       Double?
            let createdAt:    Date?
            let voiceNoteUrl: String?

            enum CodingKeys: String, CodingKey {
                case id
                case title
                case sfSymbol     = "sf_symbol"
                case jarColor     = "jar_color"
                case amount
                case createdAt    = "created_at"
                case voiceNoteUrl = "voice_note_url"
            }
        }

        // Only show last 7 days
        let sevenDaysAgo = Calendar.current.date(
            byAdding: .day, value: -7, to: Date()) ?? Date()
        let formatter = ISO8601DateFormatter()
        let cutoff = formatter.string(from: sevenDaysAgo)

        do {
            let rows: [ChildActivityRow] = try await supabase
                .from("child_activity")
                .select()
                .eq("child_id", value: childId.uuidString)
                .gte("created_at", value: cutoff)
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value

            let items = rows.map { row in
                ChildActivityItem(
                    name:         row.title,
                    timestamp:    row.createdAt    ?? Date(),
                    amount:       row.amount       ?? 0,
                    jarColor:     row.jarColor     ?? "blue",
                    sfSymbol:     row.sfSymbol     ?? "bell.fill",
                    voiceNoteUrl: row.voiceNoteUrl)
            }

            await MainActor.run { activity = items }

        } catch {
            print("❌ fetchRecentActivity: \(error)")
        }
    }
    func jarImage(amount: Double,
                  color: String) -> String {
        if amount == 0       { return "Empty jar \(color)" }
        else if amount < 50  { return "one jar \(color)" }
        else if amount < 100 { return "two jar \(color)" }
        else                 { return "full jar \(color)" }
    }

    func iconBg(_ c: String) -> Color {
        switch c {
        case "yellow": return Color(hex: "FFF3E0")
        case "green":  return Color(hex: "E8F5E9")
        case "red":    return Color(hex: "FFEBEE")
        case "purple": return Color(hex: "F3E8FF")
        default:       return Color(hex: "EBF4FF")
        }
    }

    func iconColor(_ c: String) -> Color {
        switch c {
        case "yellow": return Color(hex: "C8923A")
        case "green":  return Color(hex: "2E7D32")
        case "red":    return Color(hex: "C62828")
        case "purple": return Color(hex: "7C3AED")
        default:       return Color(hex: "185FA5")
        }
    }
}

// ── Jar card ─────────────────────────────
struct JarCardHome: View {
    let imageName:   String
    let label:       String
    let amount:      Double
    let borderColor: Color
    let jarWidth:    CGFloat
    let jarHeight:   CGFloat

    var body: some View {
        VStack(spacing: 8) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: jarWidth, height: jarHeight)
                .padding(.top, 6)
            Text(label)
                .font(.system(
                    size: 13,
                    weight: .semibold,
                    design: .rounded))
                .foregroundColor(Color(hex: "1B3A6B"))
            Text("\(Int(amount)) SAR")
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(Color(hex: "8A9BB0"))
                .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity)
    }
}

// ═══════════════════════════════════════════════
// MARK: - Sign Out Button (child-friendly)
// ═══════════════════════════════════════════════

struct SignOutButton: View {
    @AppStorage("isChildLoggedIn") var isChildLoggedIn = false
    @State private var showConfirm = false

    var body: some View {
        Button { showConfirm = true } label: {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: "door.left.hand.open")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .confirmationDialog(
            "Leave Nafaqati? 👋",
            isPresented: $showConfirm,
            titleVisibility: .visible
        ) {
            Button("Yes, sign out", role: .destructive) {
                UserDefaults.standard.removeObject(forKey: "childId")
                UserDefaults.standard.removeObject(forKey: "parentId")
                UserDefaults.standard.removeObject(forKey: "childName")
                UserDefaults.standard.removeObject(forKey: "childAvatar")
                UserDefaults.standard.removeObject(forKey: "savedGoals")
                UserDefaults.standard.removeObject(forKey: "savedChildActivity")
                isChildLoggedIn = false
            }
            Button("Stay", role: .cancel) {}
        } message: {
            Text("You can always come back with your code 🔑")
        }
    }
}

// ═══════════════════════════════════════════════
// MARK: - Smart Avatar View (emoji OR photo URL)
// ═══════════════════════════════════════════════

struct ChildAvatarView: View {
    let avatar: String
    let size: CGFloat

    var isUrl: Bool {
        avatar.hasPrefix("http://") || avatar.hasPrefix("https://")
    }

    var body: some View {
        Group {
            if isUrl, let url = URL(string: avatar) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    case .failure, .empty:
                        fallbackView
                    @unknown default:
                        fallbackView
                    }
                }
            } else {
                Text(avatar.isEmpty ? "🧒" : avatar)
                    .font(.system(size: size * 0.6))
            }
        }
        .frame(width: size, height: size)
    }

    private var fallbackView: some View {
        Image(systemName: "person.fill")
            .font(.system(size: size * 0.5))
            .foregroundColor(Color(hex: "2D6DAB"))
    }
}
