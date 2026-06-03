import SwiftUI

struct JarInfoSheet: View {

    @Environment(\.dismiss) var dismiss
    @State private var currentPage = 0
    @State private var animateCoin = false
    @State private var animateHeart = false
    @State private var animateShopping = false

    let pages: [JarPage] = [
        JarPage(
            emoji:       "🏦",
            title:       "Saving Jar",
            subtitle:    "Your future treasure chest!",
            description: "50% of every allowance goes here.\nThis is money you save for big goals.\nThe more you save, the closer you get!",
            color:       Color(hex: "C8923A"),
            bgColor:     Color(hex: "FFF8EC"),
            facts: [
                "💡 Saving money makes it grow",
                "🎯 Use it for your goals",
                "⭐ The more you save, the richer you get"
            ]
        ),
        JarPage(
            emoji:       "💚",
            title:       "Giving Jar",
            subtitle:    "Spread kindness everywhere!",
            description: "20% of every allowance goes here.\nUse this money to help others.\nGiving makes you and others happy!",
            color:       Color(hex: "4CAF50"),
            bgColor:     Color(hex: "F0FAF0"),
            facts: [
                "🤝 Help a friend in need",
                "🎁 Buy a gift for someone you love",
                "🌍 Donate to a good cause"
            ]
        ),
        JarPage(
            emoji:       "🛍️",
            title:       "Spending Jar",
            subtitle:    "Smart spending is a superpower!",
            description: "30% of every allowance goes here.\nUse it for things you want now.\nBut always think before you spend!",
            color:       Color(hex: "E05555"),
            bgColor:     Color(hex: "FFF0F0"),
            facts: [
                "🤔 Think: do I need it or want it?",
                "💸 Spend wisely on things you love",
                "📊 Track what you spend"
            ]
        )
    ]

    var body: some View {
        ZStack {
            pages[currentPage].bgColor
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // Header
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(
                                pages[currentPage].color
                                    .opacity(0.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i == currentPage
                                  ? pages[currentPage].color
                                  : pages[currentPage].color
                                    .opacity(0.25))
                            .frame(width: i == currentPage
                                   ? 24 : 8,
                                   height: 8)
                            .animation(.spring(
                                response: 0.3),
                                       value: currentPage)
                    }
                }
                .padding(.top, 8)

                Spacer()

                // Animated emoji
                ZStack {
                    Circle()
                        .fill(pages[currentPage].color
                            .opacity(0.15))
                        .frame(width: 140, height: 140)
                        .scaleEffect(animateCoin ? 1.08 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.2)
                            .repeatForever(
                                autoreverses: true),
                            value: animateCoin)

                    Text(pages[currentPage].emoji)
                        .font(.system(size: 72))
                        .rotationEffect(
                            .degrees(animateCoin ? 8 : -8))
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(
                                autoreverses: true),
                            value: animateCoin)
                }
                .onAppear { animateCoin = true }

                Spacer().frame(height: 24)

                // Title
                Text(pages[currentPage].title)
                    .font(.system(
                        size: 32,
                        weight: .bold,
                        design: .rounded))
                    .foregroundColor(pages[currentPage].color)

                Text(pages[currentPage].subtitle)
                    .font(.system(
                        size: 16,
                        design: .rounded))
                    .foregroundColor(
                        pages[currentPage].color.opacity(0.7))
                    .padding(.top, 4)

                Spacer().frame(height: 20)

                // Description
                Text(pages[currentPage].description)
                    .font(.system(
                        size: 15,
                        design: .rounded))
                    .foregroundColor(Color(hex: "1B3A6B"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer().frame(height: 24)

                // Facts
                VStack(spacing: 12) {
                    ForEach(
                        pages[currentPage].facts,
                        id: \.self) { fact in
                        HStack(spacing: 12) {
                            Text(fact)
                                .font(.system(
                                    size: 14,
                                    design: .rounded))
                                .foregroundColor(
                                    Color(hex: "1B3A6B"))
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.white
                            .opacity(0.8))
                        .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // Navigation buttons
                HStack(spacing: 16) {
                    if currentPage > 0 {
                        Button {
                            withAnimation(.spring(
                                response: 0.4)) {
                                currentPage -= 1
                                animateCoin = false
                                DispatchQueue.main
                                    .asyncAfter(
                                        deadline: .now()
                                        + 0.1) {
                                    animateCoin = true
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName:
                                    "chevron.left")
                                Text("Back")
                            }
                            .font(.system(
                                size: 16,
                                weight: .semibold,
                                design: .rounded))
                            .foregroundColor(
                                pages[currentPage].color)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.white)
                            .cornerRadius(27)
                        }
                    }

                    Button {
                        if currentPage < 2 {
                            withAnimation(.spring(
                                response: 0.4)) {
                                currentPage += 1
                                animateCoin = false
                                DispatchQueue.main
                                    .asyncAfter(
                                        deadline: .now()
                                        + 0.1) {
                                    animateCoin = true
                                }
                            }
                        } else {
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(currentPage < 2
                                 ? "Next"
                                 : "Got it! 🎉")
                            if currentPage < 2 {
                                Image(systemName:
                                    "chevron.right")
                            }
                        }
                        .font(.system(
                            size: 16,
                            weight: .semibold,
                            design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(pages[currentPage].color)
                        .cornerRadius(27)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .animation(.easeInOut(duration: 0.3),
                   value: currentPage)
    }
}

struct JarPage {
    let emoji:       String
    let title:       String
    let subtitle:    String
    let description: String
    let color:       Color
    let bgColor:     Color
    let facts:       [String]
}
