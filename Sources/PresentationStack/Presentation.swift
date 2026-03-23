//
//  Presentation.swift
//  PresentationStack
//
//  Created by TangTao on 2026/3/9.
//

import SwiftUI
import NavigationValues

public final class Presentation: ScreenContext {
    @Observable
    class Items {
        struct Custom {
            let onDismiss: (() -> Void)?
            let buildContent: (AnyIdentifiable) -> AnyView
        }
        
        var item: Item? { sheetItem ?? fullScreenCoverItem }
        var sheetItem: Item?
        var fullScreenCoverItem: Item?
        @ObservationIgnored var custom: Custom? = nil
        
        init(sheetItem: Item? = nil, fullScreenCoverItem: Item? = nil) {
            self.sheetItem = sheetItem
            self.fullScreenCoverItem = fullScreenCoverItem
        }
    }
    
    typealias Destinations = [ObjectIdentifier: (AnyIdentifiable, Presentation) -> AnyView]
    
    public enum Style: Equatable, Hashable, Sendable {
        case sheet
        case fullScreenCover
    }
    
    public struct Item: Identifiable, Equatable, Hashable, @unchecked Sendable {
        public var id: UUID = UUID()
        
        let style: Style
        let value: AnyIdentifiable
        var type: ObjectIdentifier { value.type }
        
        init<V: Identifiable>(style: Style, value: V) {
            self.style = style
            self.value = AnyIdentifiable(base: value)
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(style)
            hasher.combine(value.id)
            hasher.finalize()
        }
        
        public static func == (lhs: Item, rhs: Item) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
    }
    
    let items: Items = Items()
    var destinations: Destinations = [:]
    var dismissAction: DismissAction?
    
    public var item: Item? {
        (previous as? Presentation)?.items.item
    }
    var sheetItem: Item? {
        get { items.sheetItem }
        set { items.sheetItem = newValue }
    }
    var fullScreenCoverItem: Item? {
        get { items.fullScreenCoverItem }
        set {
            items.fullScreenCoverItem = newValue
        }
    }

    public required init() {
        
    }
    
    func addDestination<D: Identifiable, C: View>(_ data: D.Type, destination: @escaping (D) -> C) {
        destinations[ObjectIdentifier(data)] = { anyIdentifiable, presentation in
            guard let d = anyIdentifiable.base as? D else {
                return AnyView(Text("⚠️"))
            }
            return AnyView(destination(d))
        }
    }
    
    func resolveView(_ item: Item) -> AnyView {
        destinations[item.type]?(item.value, self)
        ??  (previous as? Presentation)?.resolveView(item)
        ?? AnyView(Text("⚠️"))
    }
    
    func present<Item: Identifiable>(
        _ item: Item,
        style: Style,
        onDismiss: (() -> Void)?,
        buildContent: @escaping (AnyIdentifiable) -> AnyView
    ) {
        items.custom = Items.Custom(onDismiss: onDismiss, buildContent: buildContent)
        switch style {
        case .sheet:
            items.sheetItem = Presentation.Item(style: style, value: item)
        case .fullScreenCover:
            items.fullScreenCoverItem = Presentation.Item(style: style, value: item)
        }
    }
    
    @discardableResult
    @MainActor func dismiss() -> Bool {
        guard let dismissAction, item != nil else { return false }
        dismissAction()
        return true
    }
    
    public override func cleanup() {
        super.cleanup()
        destinations.removeAll()
        items.custom = nil
    }
}

extension Presentation {
    func isManaged(by manager: PresentationManager) -> Bool {
        return manager.presentations.contains(where: { $0 === self })
    }
}
