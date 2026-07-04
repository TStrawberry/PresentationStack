//
//  PresentationStack.swift
//  PresentationStack
//
//  Created by TangTao on 2026/3/9.
//

import SwiftUI
import NavigationValues

public typealias PresentationPath = PresentationManager

public struct PresentationStack<Content: View>: View {
    let presentationManager: PresentationManager
    let content: Content
    
    @State var item: Presentation.Item? = nil
    @State var root = ScreenContext()
    
    public init(path: PresentationPath, @ViewBuilder contentBuilder: () -> Content) {
        self.presentationManager = path
        self.content = contentBuilder()
    }
    
    public var body: some View {
        content
            .screenContext(presentationManager.root)
            .setupPresentations(.constant(presentationManager.root))
            .linkScreens()
            .onPreferenceChange(ScreenContext.Preference.self, perform: { screenContexts in
                guard let presentations = screenContexts as? [Presentation] else { return }
                presentationManager.presentations = presentations
            })
            .screenContext(presentationManager)
            .environment(\.screenContext, root)
    }
}

extension View {
    @ViewBuilder
    func setupPresentations(_ presentation: Binding<Presentation>) -> some View {
        Fallthrough(view: self, key: ScreenContext.Preference.self)
            .present(
                sheetItem: presentation.sheetItem,
                fullScreenCoverItem: presentation.fullScreenCoverItem,
                onDismiss: {
                    presentation.wrappedValue.config.onDismiss()

                    presentation.wrappedValue.sheetItem = nil
                    presentation.wrappedValue.fullScreenCoverItem = nil
                },
                content: { item in
                    if let buildContent = presentation.wrappedValue.config.buildContent {
                        buildContent(item.value)
                    } else {
                        presentation.wrappedValue.resolveView(item)
                    }
                }
            )
    }
}
