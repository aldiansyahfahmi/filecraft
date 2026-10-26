import SwiftUI
import UniformTypeIdentifiers

public struct RadialFanWheelView: View {
    @ObservedObject public var model: RadialFanViewModel
    public var onSelectAction: ((RadialPetalAction, [URL]) -> Void)?
    public var onDismiss: (() -> Void)?

    @State private var animateIn: Bool = true

    private var activeActions: [RadialPetalAction] {
        model.activeActions
    }

    public init(
        model: RadialFanViewModel,
        onSelectAction: ((RadialPetalAction, [URL]) -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.model = model
        self.onSelectAction = onSelectAction
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            // Invisible background for dismissing on click outside
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    onDismiss?()
                }

            VStack(spacing: 14) {
                // Top Hotkey Guidance Pill
                HStack(spacing: 6) {
                    modeShortcutBadge(symbol: "⇧", name: "Convert", mode: .conversions)
                    modeShortcutBadge(symbol: "⌘", name: "Tools", mode: .tools)
                    modeShortcutBadge(symbol: "⌃", name: "Actions", mode: .actions)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.96))
                )
                .overlay(
                    Capsule()
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.20), radius: 10, y: 3)
                .padding(.top, 14)

                // The Authentic Annular FileCraft Wheel
                ZStack {
                    // Ambient Central Glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.32, blue: 0.0, opacity: 0.22),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 132
                            )
                        )
                        .frame(width: 264, height: 264)

                    // Continuous Frosted Glass Backdrop Ring (.fan-glass)
                    FileCraftBackdropRing(innerRadius: 42.6, outerRadius: FileCraftGeometry.backdrop)
                        .fill(Color(red: 0.75, green: 0.79, blue: 0.80, opacity: 0.28))
                        .background(
                            FileCraftBackdropRing(innerRadius: 42.6, outerRadius: FileCraftGeometry.backdrop)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            FileCraftBackdropRing(innerRadius: 42.6, outerRadius: FileCraftGeometry.backdrop)
                                .stroke(Color.white.opacity(0.35), lineWidth: 1)
                        )
                        .frame(width: 272, height: 272)
                        .shadow(color: Color(red: 0.15, green: 0.20, blue: 0.22, opacity: 0.16), radius: 6, x: 0, y: 4)

                    // Sector Petals
                    ForEach(Array(activeActions.enumerated()), id: \.element.id) { index, action in
                        let isHovered = (model.hoveredAction == action)
                        FileCraftPetalShape(index: index, totalCount: activeActions.count)
                            .fill(
                                isHovered
                                    ? AnyShapeStyle(Color(red: 1.0, green: 0.32, blue: 0.0)) // Vibrant Orange #FF5200
                                    : AnyShapeStyle(
                                        LinearGradient(
                                            stops: [
                                                .init(color: Color.white.opacity(0.85), location: 0.0),
                                                .init(color: Color(red: 0.95, green: 0.965, blue: 0.97, opacity: 0.65), location: 0.68),
                                                .init(color: Color(red: 0.957, green: 0.965, blue: 0.965, opacity: 0.78), location: 1.0)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(
                                FileCraftPetalShape(index: index, totalCount: activeActions.count)
                                    .stroke(
                                        isHovered
                                            ? Color(red: 0.76, green: 0.40, blue: 0.20, opacity: 0.44)
                                            : Color(red: 0.365, green: 0.40, blue: 0.40, opacity: 0.22),
                                        lineWidth: isHovered ? 1.0 : 0.75
                                    )
                            )
                            .shadow(color: Color(red: 0.15, green: 0.20, blue: 0.22, opacity: isHovered ? 0.24 : 0.12), radius: 5, y: 3)
                            .animation(.easeInOut(duration: 0.12), value: isHovered)
                    }
                    .frame(width: 272, height: 272)

                    // Petal Labels & Icons
                    ForEach(Array(activeActions.enumerated()), id: \.element.id) { index, action in
                        let isHovered = (model.hoveredAction == action)
                        let centerOffset = FileCraftGeometry.labelCenter(index: index, total: activeActions.count)

                        Group {
                            if action.isConversion {
                                Text(action.title)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(isHovered ? .white : Color(red: 0.08, green: 0.09, blue: 0.09))
                                    .shadow(color: isHovered ? Color.black.opacity(0.15) : Color.white.opacity(0.35), radius: 1, y: 0.5)
                            } else {
                                VStack(spacing: 2) {
                                    Image(systemName: action.iconName)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(isHovered ? .white : Color(red: 0.12, green: 0.14, blue: 0.14))
                                    Text(action.title)
                                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                        .foregroundColor(isHovered ? .white : Color(red: 0.12, green: 0.14, blue: 0.14))
                                        .lineLimit(1)
                                }
                                .shadow(color: isHovered ? Color.black.opacity(0.15) : Color.white.opacity(0.35), radius: 1, y: 0.5)
                            }
                        }
                        .position(x: 136 + centerOffset.x, y: 136 + centerOffset.y)
                        .allowsHitTesting(false)
                    }
                    .frame(width: 272, height: 272)

                    // Center FileCraft Capsule (.fan-center-label)
                    let centerText = model.hoveredAction?.title ?? model.defaultCenterTitle
                    let isToolOrAction = (model.hoveredAction?.isConversion == false)
                    Button {
                        if let action = model.hoveredAction {
                            SoundManager.shared.playActionComplete()
                            onSelectAction?(action, model.sourceURLs)
                        } else {
                            SoundManager.shared.playActionComplete()
                            onSelectAction?(.floatShelf, model.sourceURLs)
                        }
                    } label: {
                        Text(centerText)
                            .font(.system(size: isToolOrAction ? 9.5 : 12.5, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.08, green: 0.09, blue: 0.09))
                            .lineLimit(1)
                            .frame(width: 70, height: 32)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.85))
                                    .background(Capsule().fill(.ultraThinMaterial))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.75), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.10), radius: 5, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
                .frame(width: 272, height: 272)
                .scaleEffect(animateIn ? 1.0 : 0.85)
                .opacity(1.0)
                .animation(.spring(response: 0.28, dampingFraction: 0.75), value: animateIn)

                Spacer(minLength: 0)
            }
        }
        .frame(width: 360, height: 380)
        .onAppear {
            animateIn = true
        }
    }

    private func modeShortcutBadge(symbol: String, name: String, mode: ConversionFanMode) -> some View {
        let isCurrent = model.fanMode == mode
        return Button {
            model.switchMode(mode)
        } label: {
            HStack(spacing: 5) {
                Text(symbol)
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .foregroundColor(isCurrent ? .white : Color(red: 0.22, green: 0.25, blue: 0.23))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isCurrent ? Color.white.opacity(0.25) : Color(red: 0.92, green: 0.93, blue: 0.92))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(isCurrent ? Color.white.opacity(0.4) : Color(red: 0.78, green: 0.80, blue: 0.78), lineWidth: 0.5)
                    )

                Text(name)
                    .font(.system(size: 12.5, weight: isCurrent ? .bold : .semibold, design: .rounded))
                    .foregroundColor(isCurrent ? .white : Color(red: 0.16, green: 0.18, blue: 0.18))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(isCurrent ? Color(red: 1.0, green: 0.32, blue: 0.0) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
