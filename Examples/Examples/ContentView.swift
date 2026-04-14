import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            BasicColorsExample()
                .tabItem {
                    Label("Basic", systemImage: "paintbrush")
                }

            MassiveTabsExample()
                .tabItem {
                    Label("300 Tabs", systemImage: "infinity")
                }

            DateTabsExample()
                .tabItem {
                    Label("Dates", systemImage: "calendar")
                }

            VerticalTabsExample()
                .tabItem {
                    Label("Vertical", systemImage: "arrow.up.and.down")
                }
        }
    }
}
