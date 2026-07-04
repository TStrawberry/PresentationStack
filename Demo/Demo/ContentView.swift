//
//  ContentView.swift
//  Demo
//
//  Created by TangTao on 2026/3/9.
//

import SwiftUI
import PresentationStack
import NavigationValues
import MetricKit

@Observable
@MainActor
class PathContainer {
    static let shared = PathContainer()
    
    var presentationPath: PresentationPath = PresentationPath()
    
    init() { }
}

struct Screen: View {
    @Environment(\.screenContext.navigationPath) var navigationPath
    @Environment(\.screenContext) var screenContext
    
    @State var isSheet: Bool = false
    @State var timer: Timer?
    
    @State var isPresented: Bool = false
    
    @State var session: PresentationSession? = nil
    
    var body: some View {
        @Bindable var bindableSreenContext = screenContext
        
        VStack(spacing: 20) {
            TextField("name", text: $bindableSreenContext.stringValue)
                .accessibilityIdentifier("screen.nameField")

            Button("Present Sheet") {
                Task {
                    session = PathContainer.shared.presentationPath.sheetPresentation(screenContext.stringValue)
                    
                    await session?.present()
                }
            }
            .accessibilityIdentifier("screen.presentSheet")
            .onChange(of: session?.status, { oldValue, newValue in
                print(newValue)
            })
            
            Button("Present fullScreenCover") {
                Task {
                    await PathContainer.shared.presentationPath.presentFullScreenCover(screenContext.stringValue)
                }
            }
            .accessibilityIdentifier("screen.presentFullScreenCover")

            Button("Dismiss to root") {
                Task {
                    await PathContainer.shared.presentationPath.dismissToRoot()
                }
            }
            .accessibilityIdentifier("screen.dismissToRoot")
            
            Button("Dismiss last 2") {
                Task {
                    await PathContainer.shared.presentationPath.dismissLast(2)
                }
            }
            .accessibilityIdentifier("screen.dismissLast2")
            
            Button ("Push") {
                screenContext.navigationPath.wrappedValue.append(screenContext.stringValue)
            }
            .accessibilityIdentifier("screen.push")
            
            Button("Start timer") {
                var count = 0
                timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
                    count += 1
                    screenContext.stringValue = "\(count)"
                })
            }
            .accessibilityIdentifier("screen.startTimer")
            
            Button("Print graph") {
                print(PathContainer.shared.presentationPath.graph().joined(separator: "\n"))
            }
            .accessibilityIdentifier("screen.printGraph")
            
            Button("Custom sheet") {
                isPresented = true
            }
            .accessibilityIdentifier("screen.customSheet")
        }
        .withPresentationStack.sheet(isPresented: $isPresented) {
            Screen()
                .modifier(NavigationPathViewModifier())
                .navigationContext()
        }
    }
}

@MainActor extension String: @retroactive Identifiable {
    public var id: String {
        self
    }
}

extension ScreenContext {
    @ValueEntry(.observationIgnored)
    var navigationPath = Binding<NavigationPath>.constant(NavigationPath())
    
    @ValueEntry 
    var stringValue: String = "default value"
}

extension ScreenContext {
    func graph() -> [String] {
        ["\(type(of: self))"] + children.flatMap { $0.graph() }.map { "  " + $0 }
    }
}

struct NavigationPathViewModifier: ViewModifier {
    @State var path = NavigationPath()
    @Environment(\.screenContext) var screenContext
    
    @ViewBuilder func body(content: Content) -> some View {
        NavigationStack(path: $path) {
            content
                .environment(\.screenContext.navigationPath, $path)
                .transformEnvironment(\.screenContext, transform: { rootScreenContext in
                    /// Connect the topest screen and the its behind screen
                    guard let previousTop = (screenContext.parent as? Presentation)?.previous?.top()
                    else { return }
                    rootScreenContext.previous = previousTop
                    previousTop.next = rootScreenContext
                })
                .screenContext()
                .navigationDestination(for: String.self) { name in
                    Screen()
                        .screenContext()
                }
        }
    }
}

extension ScreenContext {
    @ValueEntry(.observationIgnored) var tabTag: Int? = nil
}

struct ContentView: View {
    @State var pathContainer = PathContainer.shared
    
    @State var selection: Int = 0
    
    var body: some View {
        PresentationStack(path: pathContainer.presentationPath) {
            TabView(selection: $selection) {
                Screen()
                    .modifier(NavigationPathViewModifier())
                    .tabItem {
                        Image(systemName: "house")
                        Text("Home")
                    }
                    .tag(0)
                    .environment(\.screenContext.tabTag, 0)
                    .navigationContext(linkToPrevious: false)
                
                Screen()
                    .modifier(NavigationPathViewModifier())
                    .tabItem {
                        Image(systemName: "star")
                        Text("Favorites")
                    }
                    .tag(1)
                    .environment(\.screenContext.tabTag, 1)
                    .navigationContext(linkToPrevious: false)
                
                Screen()
                    .modifier(NavigationPathViewModifier())
                    .tabItem {
                        Image(systemName: "person")
                        Text("Profile")
                    }
                    .tag(2)
                    .environment(\.screenContext.tabTag, 2)
                    .navigationContext(linkToPrevious: false)
            }
            .modifier(TabManagerViewModifier(selection: $selection))
            .presentationDestination(for: String.self) { name in
                Screen()
                    .modifier(NavigationPathViewModifier())
                    .navigationContext(linkToPrevious: false)
            }
        }
    }
}

struct TabManagerViewModifier<H: Hashable>: ViewModifier {
    class TabView: ScreenContext {
        var selectedTag: Int? = nil
        
        override func top() -> ScreenContext {
            return children.first(where: { $0.tabTag == selectedTag })?.top() ?? self
        }
    }
    
    @State var tabManager = TabView()
    @Binding var selection: H
    
    @ViewBuilder
    func body(content: Content) -> some View {
        content
            .onChange(of: selection, initial: true) { oldValue, newValue in
                tabManager.selectedTag = newValue as? Int
            }
            .screenContext(tabManager, linkToPrevious: false)
            .scrollTargetBehavior(.viewAligned)
    }
}

#Preview {
    ContentView()
}
