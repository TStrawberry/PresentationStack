//
//  CustomPresentation.swift
//  PresentationStack
//
//  Created by TangTao on 2026/6/1.
//

import SwiftUI
import NavigationValues

public extension View {
    var withPresentationStack: WithPresentationStack<Self> {
        WithPresentationStack(view: self)
    }
}

@MainActor
public struct WithPresentationStack<V: View> {
    let view: V
    
    public func sheet<Item, Content>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View where Item : Identifiable, Content : View {
        view
            .modifier(
                CustomPresentationViewModifier(
                    item: item,
                    style: .sheet,
                    onDismiss: {
                        item.wrappedValue = nil
                        onDismiss?()
                    },
                    buildContent: content
                )
            )
    }
    
    public func sheet<Content>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View where Content : View {
        sheet(
            item: Binding<True?>(
                get: {
                    isPresented.wrappedValue ? True() : nil
                },
                set: { value in
                    isPresented.wrappedValue = value != nil
                }
            ),
            onDismiss: onDismiss,
            content: { _ in content() }
        )
    }
    
    public func fullScreenCover<Item, Content>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View where Item : Identifiable, Content : View {
        view
            .modifier(
                CustomPresentationViewModifier(
                    item: item,
                    style: .fullScreenCover,
                    onDismiss: {
                        item.wrappedValue = nil
                        onDismiss?()
                    },
                    buildContent: content
                )
            )
    }
    
    public func fullScreenCover<Content>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View where Content : View {
        fullScreenCover(
            item: Binding<True?>(
                get: {
                    isPresented.wrappedValue ? True() : nil
                },
                set: { value in
                    isPresented.wrappedValue = value != nil
                }
            ),
            onDismiss: onDismiss,
            content: { _ in content() }
        )
    }
}

struct CustomPresentationViewModifier<Item: Identifiable, SheetContent: View>: ViewModifier {
    @Environment(\.dismiss) var dismiss
    @Environment(\.screenContext) var screenContext
    
    let style: Presentation.Style
    @Binding var item: Item?
    
    let onDismiss: (() -> Void)?
    let buildContent: (Item) -> SheetContent
    
    init(
        item: Binding<Item?>,
        style: Presentation.Style,
        onDismiss: (() -> Void)?,
        buildContent: @escaping (Item) -> SheetContent
    ) {
        self.onDismiss = onDismiss
        self.style = style
        self._item = item
        self.buildContent = buildContent
    }
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if let presentation = searchPresentation() {
            @Bindable var bindablePresentation = presentation
            content
                .onChange(of: item?.id) { _, _ in
                    if let it = item {
                        bindablePresentation.present(it, style: style, onDismiss: onDismiss) { _ in
                            AnyView(buildContent(it).presentation())
                        }
                    } else {
                        bindablePresentation.sheetItem = nil
                    }
                }
        } else {
            Text("⚠️ Failed to find a presentation stack.")
        }
    }
    
    func searchPresentation() -> Presentation? {
        var ctx: ScreenContext? = screenContext
        
        while ctx != nil {
            if let presentation = ctx as? Presentation {
                return presentation
            }
            ctx = ctx?.parent
        }
        return nil
    }
}

