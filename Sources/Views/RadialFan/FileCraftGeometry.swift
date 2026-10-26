import Foundation
import CoreGraphics
import SwiftUI

public struct FileCraftGeometry {
    public static let inner: CGFloat = 48 * 0.8 * 1.1 + 8 * 0.8       // 48.64
    public static let outer: CGFloat = 166 * 0.8 * 0.9                 // 119.52
    public static let backdrop: CGFloat = 166 * 0.8 * 0.9 + 8 * 0.8    // 125.92
    public static let gap: CGFloat = 5 * 0.8                           // 4.0
    public static let corner: CGFloat = 28 * 0.8 * 0.9                 // 20.16
    public static let labelInner: CGFloat = 50 * 0.8                   // 40.0

    public static func angleFor(index: Int, total: Int) -> CGFloat {
        let base: CGFloat = (total == 3 ? .pi : .pi / 2.0)
        return base - (.pi * 2.0 * CGFloat(index) / CGFloat(total))
    }

    public static func point(radius: CGFloat, angle: CGFloat) -> CGPoint {
        CGPoint(x: cos(angle) * radius, y: -sin(angle) * radius)
    }

    public static func labelCenter(index: Int, total: Int) -> CGPoint {
        let radius = labelInner + (outer - labelInner) * 0.56
        let angle = angleFor(index: index, total: total)
        return point(radius: radius, angle: angle)
    }

    public static func petalPath(index: Int, total: Int) -> CGPath {
        let path = CGMutablePath()
        let a = angleFor(index: index, total: total)
        let n = CGFloat.pi * 2.0 / CGFloat(total)
        let l = a - n / 2.0
        let s = a + n / 2.0

        func r(_ J: CGFloat) -> CGFloat {
            asin(min(0.95, gap / 2.0 / max(J, gap / 2.0 + 0.01)))
        }

        let d = l + r(outer)
        let i = s - r(outer)
        let c = l + r(inner)
        let g = s - r(inner)

        let f = min(0.15, (i - d) * 0.24)
        let u = min(0.18, (g - c) * 0.18)

        let v = inner / max(0.01, cos(u))
        let y = v + inner * tan(u)
        let O = outer - corner

        let p1 = point(radius: y, angle: l + r(y))
        path.move(to: p1)

        let p2 = point(radius: O, angle: l + r(O))
        path.addLine(to: p2)

        let p3Ctrl = point(radius: outer, angle: d)
        let p3To = point(radius: outer, angle: d + f)
        path.addQuadCurve(to: p3To, control: p3Ctrl)

        path.addArc(center: .zero, radius: outer, startAngle: -(d + f), endAngle: -(i - f), clockwise: true)

        let p5Ctrl = point(radius: outer, angle: i)
        let p5To = point(radius: O, angle: s - r(O))
        path.addQuadCurve(to: p5To, control: p5Ctrl)

        let p6 = point(radius: y, angle: s - r(y))
        path.addLine(to: p6)

        let p7Ctrl = point(radius: v, angle: s - r(v))
        let p7To = point(radius: inner, angle: g - u)
        path.addQuadCurve(to: p7To, control: p7Ctrl)

        path.addArc(center: .zero, radius: inner, startAngle: -(g - u), endAngle: -(c + u), clockwise: false)

        let p9Ctrl = point(radius: v, angle: l + r(v))
        path.addQuadCurve(to: p1, control: p9Ctrl)

        path.closeSubpath()
        return path
    }

    public static func hitTest(x: CGFloat, y: CGFloat, total: Int) -> Int? {
        let dist = hypot(x, y)
        if total <= 0 || dist < inner || dist > outer {
            return nil
        }
        let angle = atan2(-y, x)
        let step = CGFloat.pi * 2.0 / CGFloat(total)
        let rawDiff = (angleFor(index: 0, total: total) - angle).truncatingRemainder(dividingBy: .pi * 2.0)
        let normalizedDiff = (rawDiff + .pi * 2.0).truncatingRemainder(dividingBy: .pi * 2.0)
        let candidateIndex = Int(round(normalizedDiff / step)) % total

        let candidateAngle = angleFor(index: candidateIndex, total: total)
        let diff = atan2(sin(angle - candidateAngle), cos(angle - candidateAngle))
        let gapAngle = asin(min(0.95, gap / 2.0 / max(dist, gap / 2.0 + 0.01)))

        if abs(diff) > (step / 2.0 - gapAngle) {
            return nil
        }
        return candidateIndex
    }
}

public struct FileCraftPetalShape: Shape {
    public let index: Int
    public let totalCount: Int

    public init(index: Int, totalCount: Int) {
        self.index = index
        self.totalCount = totalCount
    }

    public func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let cgPath = FileCraftGeometry.petalPath(index: index, total: totalCount)
        var transform = CGAffineTransform(translationX: center.x, y: center.y)
        if let transformed = cgPath.copy(using: &transform) {
            return Path(transformed)
        }
        return Path(cgPath)
    }
}

public struct FileCraftBackdropRing: Shape {
    public let innerRadius: CGFloat
    public let outerRadius: CGFloat

    public init(innerRadius: CGFloat = 42.6, outerRadius: CGFloat = FileCraftGeometry.backdrop) {
        self.innerRadius = innerRadius
        self.outerRadius = outerRadius
    }

    public func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        path.addArc(center: center, radius: outerRadius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
        path.addArc(center: center, radius: innerRadius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: true)
        path.closeSubpath()
        return path
    }
}
