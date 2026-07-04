//
//  Presentation.swift
//  PresentationStack
//
//  Created by TangTao on 2026/3/9.
//

import SwiftUI
import NavigationValues

public final class Presentation: ScreenContext {
    typealias Destinations = [ObjectIdentifier: (AnyIdentifiable, Presentation) -> AnyView]
    
    @Observable
    class Config {
        var item: Item? { sheetItem ?? fullScreenCoverItem }
        var sheetItem: Item?
        var fullScreenCoverItem: Item?
        
        @ObservationIgnored var onDismiss: () -> Void = { }
        @ObservationIgnored var buildContent: ((AnyIdentifiable) -> AnyView)? = nil
        
        init(sheetItem: Item? = nil, fullScreenCoverItem: Item? = nil) {
            self.sheetItem = sheetItem
            self.fullScreenCoverItem = fullScreenCoverItem
        }
    }
    
    public enum Style: Equatable, Hashable, Sendable {
        case sheet
        case fullScreenCover
    }
    
    struct Item: Identifiable, Equatable, Hashable, @unchecked Sendable {
        let id: UUID = UUID()
        
        let style: Style
        let value: AnyIdentifiable
        var type: ObjectIdentifier { value.type }
        
        init<V: Identifiable>(style: Style, value: V) {
            self.style = style
            self.value = AnyIdentifiable(base: value)
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(style)
            hasher.combine(value.id)
            hasher.combine(id)
            hasher.finalize()
        }
        
        static func == (lhs: Item, rhs: Item) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
    }
    
    let config: Config = Config()
    var destinations: Destinations = [:]
    var dismissAction: DismissAction?
    
    var isDismissed: Bool {
        guard let manager = parent as? PresentationManager else { return true }
        return !manager.presentations.contains(self)
    }
 
    var item: Item? {
        (previous as? Presentation)?.config.item
    }
    var sheetItem: Item? {
        get { config.sheetItem }
        set { config.sheetItem = newValue }
    }
    var fullScreenCoverItem: Item? {
        get { config.fullScreenCoverItem }
        set { config.fullScreenCoverItem = newValue }
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
        onDismiss: (() -> Void)? = nil,
        buildContent: @escaping (AnyIdentifiable) -> AnyView
    ) {
        config.buildContent = buildContent
        if let onDismiss {
            let origin = config.onDismiss
            config.onDismiss = {
                origin()
                onDismiss()
            }
        }
        switch style {
        case .sheet:
            config.sheetItem = Presentation.Item(style: style, value: item)
        case .fullScreenCover:
            config.fullScreenCoverItem = Presentation.Item(style: style, value: item)
        }
    }
    
    @discardableResult
    @MainActor public func dismiss() async -> Bool {
        guard let manager = parent as? PresentationManager else { return false }
        await manager.dismiss(self)
        return true
    }
    
    public override func cleanup() {
        super.cleanup()
        destinations.removeAll()
        config.buildContent = nil
        config.onDismiss = { }
    }
    
    @discardableResult
    @MainActor func asyncDismiss() -> Bool {
        guard let dismissAction, item != nil else { return false }
        dismissAction()
        return true
    }
}

extension Presentation {
    func isManaged(by manager: PresentationManager) -> Bool {
        return manager.presentations.contains(where: { $0 === self })
    }
}
