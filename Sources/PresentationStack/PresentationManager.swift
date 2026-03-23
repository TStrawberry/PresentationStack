//
//  PresentationContainer.swift
//  PresentationStack
//
//  Created by TangTao on 2026/3/9.
//

import SwiftUI
import Observation
import NavigationValues

public class PresentationManager: ScreenContext {
    @Observable class ObserableItems {
        var presentations: [Presentation] = []
        
        @ObservationIgnored
        var lastPresentation: Presentation? { _presentations.last }
    }
    let obserableItems = ObserableItems()
    
    public let root: Presentation = Presentation()
    
    var presentations: [Presentation] {
        get { obserableItems.presentations }
        set { obserableItems.presentations = newValue }
    }
    
    public var topPresentation: Presentation { obserableItems.lastPresentation ?? root }
    
    public var values: [any Identifiable] {
        presentations.compactMap(\.item?.value.base)
    }
    
    public required init() {
        
    }
    
    func contains(_ value: AnyIdentifiable) -> Bool {
        return presentations.contains(where: { $0.item?.value == value })
    }
    
    public func dismiss(to item: Presentation.Item) async {
        guard let index = presentations.lastIndex(where: { $0.item == item }) else {
            return
        }
        for presentation in presentations.suffix(presentations.count - 1 - index).reversed() {
            await dismiss(presentation)
        }
    }
    
    public func dismissToRoot() async {
        for presentation in presentations.reversed() {
            await dismiss(presentation)
        }
    }
    
    public func dismissLast(_ k: UInt) async {
        for presentation in presentations.suffix(min(presentations.count, Int(k))).reversed() {
            await dismiss(presentation)
        }
    }
    
    public func dismiss(_ presentation: Presentation) async {
        guard presentation.dismiss() else { return }
        
        while self.presentations.contains(presentation) == true {
            await withCheckedContinuation { continuation in
                let _ = withObservationTracking(
                    { self.presentations },
                    onChange: {
                        Task(priority: .high) { @MainActor in
                            if self.presentations.contains(presentation) == false {
                                continuation.resume()
                            }
                        }
                    }
                )
            }
        }
    }
    
    public func present(_ item: Presentation.Item) async {
        switch item.style {
        case .sheet: topPresentation.sheetItem = item
        case .fullScreenCover: topPresentation.fullScreenCoverItem = item
        }
        
        while self.presentations.compactMap(\.item).contains(item) == false {
            await withCheckedContinuation { continuation in
                let _ = withObservationTracking(
                    { self.presentations },
                    onChange: {
                        Task { @MainActor in
                            if self.presentations.contains(where: { $0.item == item }) {
                                continuation.resume()
                            }
                        }
                    }
                )
            }
        }
    }
    
    public func presentSheet<V>(_ value: V) async where V : Identifiable {
        await present(Presentation.Item(style: .sheet, value: value))
    }
    
    public func presentFullScreenCover<V>(_ value: V) async where V : Identifiable {
        await present(Presentation.Item(style: .fullScreenCover, value: value))
    }
    
    public func present(_ items: [Presentation.Item]) async {
        for item in items {
            if Task.isCancelled { return }
            await present(item)
        }
    }
    
    public override func isParent(of child: ScreenContext) -> Bool {
        return root === child || super.isParent(of: child)
    }
    
    public override func top() -> ScreenContext {
        topPresentation.top()
    }
}
