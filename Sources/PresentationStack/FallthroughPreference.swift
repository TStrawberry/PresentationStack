//
//  FallthroughPreference.swift
//  PresentationStack
//
//  Created by TangTao on 2026/3/10.
//

import SwiftUI

struct ContainerView<V: View, Key: PreferenceKey>: View {
    let content: (Binding<Key.Value?>) -> V
    
    @State var value: Key.Value?
    
    init(key: Key.Type, @ViewBuilder content: @escaping (Binding<Key.Value?>) -> V) {
        self.content = content
    }
    
    var body: some View {
        content($value)
    }
}

struct Fallthrough<V: View, K: PreferenceKey> where K.Value: Equatable {
    let view: V
    let key: K.Type
    
    @MainActor
    @ViewBuilder
    public func present<Item, Content>(
        sheetItem: Binding<Item?>,
        fullScreenCoverItem: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View where Item : Identifiable, Content : View {
        ContainerView(key: key) { binding in
            let onDismissAction = {
                binding.wrappedValue = nil
                onDismiss?()
            }
            
            let buildContent: (Item) -> some View = { it in
                content(it)
                    .onPreferenceChange(key) { v in
                        binding.wrappedValue = v
                    }
            }
            
            view
                .overlay(alignment: .bottom) {
                    if let preference = binding.wrappedValue {
                        Color.clear.fixedSize()
                            .allowsHitTesting(false)
                            .preference(key: key, value: preference)
                    }
                }
                .sheet(
                    item: sheetItem,
                    onDismiss: onDismissAction,
                    content: buildContent
                )
                .fullScreenCover(
                    item: fullScreenCoverItem,
                    onDismiss: onDismissAction,
                    content: buildContent
                )
        }
    }
}

