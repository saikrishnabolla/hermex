import SwiftUI

/// The two sides of a Hermes server's home (#709): the Bots inbox and the session list.
enum HermesHomeTab: String {
    case bots, sessions
}

/// What both sides of a Hermes server's home share: the server's name, which titles a pushed
/// screen's back button, the server's avatar in the header, and the switch between the sides.
struct HermesHome {
    let title: String
    let avatar: SessionsHeader.Avatar
    let tab: Binding<HermesHomeTab>
}

/// The Hermes home's bar chrome (#709), the same on both sides: no top bar, since each side's
/// list leads with the session list's header (`SessionsHeader`), and a bottom bar of
/// `(filter) [Bots | Sessions] (new chat)` whose ends each side fills. The title names a pushed
/// screen's back button, and stays inline so a pushed screen such as Tasks keeps the one-line bar.
/// On iOS 26 the bar's glass pills float over the list: the system's bottom scroll edge effect
/// read as a solid band behind them, so it is hidden.
struct HermesHomeChrome<Filter: View, NewChat: View>: ViewModifier {
    let home: HermesHome
    @ViewBuilder let filter: Filter
    @ViewBuilder let newChat: NewChat

    func body(content: Content) -> some View {
        content
            .modifier(HiddenBottomScrollEdge())
            .navigationTitle(home.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .bottomBar) { filter }
                if #available(iOS 26, *) {
                    ToolbarSpacer(.flexible, placement: .bottomBar)
                    // The segmented control is its own pill; a glass one around it would double it.
                    ToolbarItem(placement: .bottomBar) { HermesHomeSwitch(tab: home.tab) }
                        .sharedBackgroundVisibility(.hidden)
                    ToolbarSpacer(.flexible, placement: .bottomBar)
                } else {
                    ToolbarItem(placement: .bottomBar) { HermesHomeSwitch(tab: home.tab) }
                }
                ToolbarItem(placement: .bottomBar) { newChat }
            }
    }
}

private struct HiddenBottomScrollEdge: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.scrollEdgeEffectHidden(true, for: .bottom)
        } else {
            content
        }
    }
}

/// `[Bots | Sessions]`. It keeps a system bar's size at accessibility text sizes; a long press
/// shows the Large Content Viewer instead.
private struct HermesHomeSwitch: View {
    @Binding var tab: HermesHomeTab

    var body: some View {
        NativeHermesHomeSwitch(tab: $tab)
            .frame(width: 200, height: 36)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .accessibilityShowsLargeContentViewer()
    }
}

private struct NativeHermesHomeSwitch: UIViewRepresentable {
    @Binding var tab: HermesHomeTab

    func makeUIView(context: Context) -> UISegmentedControl {
        let control = UISegmentedControl(items: [String(localized: "Bots"), String(localized: "Sessions")])
        control.apportionsSegmentWidthsByContent = false
        control.addTarget(context.coordinator, action: #selector(Coordinator.selectTab(_:)), for: .valueChanged)
        return control
    }

    func updateUIView(_ control: UISegmentedControl, context: Context) {
        context.coordinator.tab = $tab
        control.selectedSegmentIndex = tab == .bots ? 0 : 1
    }

    func makeCoordinator() -> Coordinator { Coordinator(tab: $tab) }

    @MainActor
    final class Coordinator: NSObject {
        var tab: Binding<HermesHomeTab>

        init(tab: Binding<HermesHomeTab>) { self.tab = tab }

        @objc func selectTab(_ control: UISegmentedControl) {
            tab.wrappedValue = control.selectedSegmentIndex == 0 ? .bots : .sessions
        }
    }
}
