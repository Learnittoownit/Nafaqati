// JarCardView.swift
// Nafaqati

import SwiftUI

// ─────────────────────────────────────────────
// MARK: - JarType Color Extension
// ─────────────────────────────────────────────
// NOTE: JarType already has a `color` property in Models.swift (returns String/hex).
// We add `jarColor` (returns SwiftUI Color) and `lightColor` here.

extension JarType {

    /// SwiftUI Color version of the jar's main color
    var jarColor: Color {
        switch self {
        case .saving:   return Color(hex: "F5A623")  // Orange
        case .spending: return Color(hex: "E05A5A")  // Red/coral
        case .giving:   return Color(hex: "4CAF82")  // Green
        }
    }

    /// Light background color for the jar body fill
    var lightColor: Color {
        switch self {
        case .saving:   return Color(hex: "FEF3DC")  // Light orange
        case .spending: return Color(hex: "FDEAEA")  // Light red
        case .giving:   return Color(hex: "E2F5EC")  // Light green
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - JarCardView
// ─────────────────────────────────────────────
// How to use:
//   JarCardView(jarType: .saving, balance: 120.0)

struct JarCardView: View {

    let jarType: JarType
    let balance: Double
    var compact: Bool = false

    var body: some View {
        VStack(spacing: compact ? 8 : 12) {

            JarIllustration(jarType: jarType, compact: compact)

            Text(jarType.displayName)
                .font(.system(size: compact ? 13 : 15, weight: .semibold))
                .foregroundColor(.nafNavy)

            Text("\(balance, specifier: "%.2f") SAR")
                .font(.system(size: compact ? 12 : 14, weight: .medium))
                .foregroundColor(.nafTextGray)
        }
        .frame(width: compact ? 100 : 120)
        .padding(.vertical, compact ? 14 : 18)
        .padding(.horizontal, compact ? 10 : 14)
        .background(Color.nafCardWhite)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

// ─────────────────────────────────────────────
// MARK: - JarIllustration
// ─────────────────────────────────────────────

struct JarIllustration: View {

    let jarType: JarType
    var compact: Bool = false

    private var size: CGFloat { compact ? 64 : 80 }

    var body: some View {
        ZStack {
            JarShape()
                .fill(jarType.lightColor)
                .frame(width: size, height: size)

            VStack(spacing: 2) {
                Spacer()
                CoinsStack(jarType: jarType, compact: compact)
            }
            .frame(width: size * 0.6, height: size * 0.7)
            .clipped()

            JarShape()
                .stroke(jarType.jarColor, lineWidth: 2)
                .frame(width: size, height: size)

            JarLid(jarType: jarType, width: size)
        }
        .frame(width: size, height: size + 8)
    }
}

// ─────────────────────────────────────────────
// MARK: - JarShape
// ─────────────────────────────────────────────

struct JarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let neckInset: CGFloat = w * 0.15
        let neckHeight: CGFloat = h * 0.18
        let cornerRadius: CGFloat = 12

        path.move(to: CGPoint(x: neckInset, y: neckHeight))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: neckHeight + h * 0.1),
            control: CGPoint(x: 0, y: neckHeight)
        )
        path.addLine(to: CGPoint(x: 0, y: h - cornerRadius))
        path.addQuadCurve(
            to: CGPoint(x: cornerRadius, y: h),
            control: CGPoint(x: 0, y: h)
        )
        path.addLine(to: CGPoint(x: w - cornerRadius, y: h))
        path.addQuadCurve(
            to: CGPoint(x: w, y: h - cornerRadius),
            control: CGPoint(x: w, y: h)
        )
        path.addLine(to: CGPoint(x: w, y: neckHeight + h * 0.1))
        path.addQuadCurve(
            to: CGPoint(x: w - neckInset, y: neckHeight),
            control: CGPoint(x: w, y: neckHeight)
        )
        path.addLine(to: CGPoint(x: neckInset, y: neckHeight))
        path.closeSubpath()
        return path
    }
}

// ─────────────────────────────────────────────
// MARK: - JarLid
// ─────────────────────────────────────────────

struct JarLid: View {
    let jarType: JarType
    let width: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(jarType.jarColor)
                .frame(width: width * 0.2, height: 6)

            RoundedRectangle(cornerRadius: 4)
                .fill(jarType.jarColor)
                .frame(width: width * 0.55, height: 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, -2)
    }
}

// ─────────────────────────────────────────────
// MARK: - CoinsStack
// ─────────────────────────────────────────────

struct CoinsStack: View {
    let jarType: JarType
    var compact: Bool = false

    private var coinWidth: CGFloat { compact ? 32 : 40 }

    var body: some View {
        VStack(spacing: 3) {
            CoinLayer(color: jarType.jarColor.opacity(0.5), width: coinWidth)
            CoinLayer(color: jarType.jarColor.opacity(0.75), width: coinWidth)
            CoinLayer(color: jarType.jarColor, width: coinWidth)
        }
    }
}

struct CoinLayer: View {
    let color: Color
    let width: CGFloat

    var body: some View {
        Ellipse()
            .fill(color)
            .frame(width: width, height: width * 0.35)
    }
}

// ─────────────────────────────────────────────
// MARK: - Preview
// ─────────────────────────────────────────────

#Preview {
    HStack(spacing: 16) {
        JarCardView(jarType: .saving, balance: 120.0)
        JarCardView(jarType: .spending, balance: 45.5)
        JarCardView(jarType: .giving, balance: 30.0)
    }
    .padding()
    .background(Color.nafBackground)
}

