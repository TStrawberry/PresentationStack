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
    
    @discardableResult
    func present(_ item: Presentation.Item) async -> Presentation? {
        switch item.style {
        case .sheet: topPresentation.sheetItem = item
        case .fullScreenCover: topPresentation.fullScreenCoverItem = item
        }
        
        repeat {
            await withCheckedContinuation { continuation in
                let _ = withObservationTracking(
                    { self.presentations },
                    onChange: {
                        Task(priority: .high) {
                            continuation.resume()
                        }
                    }
                )
            }
        } while (self.presentations.contains { $0.item == item } == false)
        return self.presentations.first(where: {  $0.item == item })
    }
    
    @discardableResult
    public func presentSheet<V>(_ value: V) async -> Presentation? where V : Identifiable {
        await present(Presentation.Item(style: .sheet, value: value))
    }
    
    @discardableResult
    public func presentFullScreenCover<V>(_ value: V) async -> Presentation?  where V : Identifiable {
        await present(Presentation.Item(style: .fullScreenCover, value: value))
    }
    
    public func dismissLast(_ k: UInt) async {
        for presentation in presentations.suffix(min(presentations.count, Int(k))).reversed() {
            await dismiss(presentation)
        }
    }
    
    public func dismiss(_ presentation: Presentation) async {
        guard presentation.asyncDismiss() else { return }
        
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
    
    public func dismissToRoot() async {
        for presentation in presentations.reversed() {
            await dismiss(presentation)
        }
    }
    
    public override func isParent(of child: ScreenContext) -> Bool {
        return root === child || super.isParent(of: child)
    }
    
    public override func top() -> ScreenContext {
        topPresentation.top()
    }
    
    func present(_ items: [Presentation.Item]) async {
        for item in items {
            if Task.isCancelled { return }
            await present(item)
        }
    }
    
    func dismiss(to item: Presentation.Item) async {
        for presentation in presentations.reversed() {
            if presentation.item == item { return }
            await dismiss(presentation)
        }
    }
}

extension PresentationManager {
    public func sheetPresentation<V>(_ value: V) -> PresentationSession  where V : Identifiable {
        PresentationSession {
            await self.present(Presentation.Item(style: .sheet, value: value))
        }
    }

    public func fullScreenCoverPresentation<V>(_ value: V) -> PresentationSession  where V : Identifiable {
        PresentationSession {
            await self.present(Presentation.Item(style: .fullScreenCover, value: value))
        }
    }
}


@Observable
@MainActor
public final class PresentationSession: Sendable {
    public enum Status: Equatable {
        case idle
        case presented
        case dismissed
    }
    
    public internal(set) var status: Status = .idle
    
    let presentAction: () async -> Presentation?
    
    init(presentAction: @escaping () async -> Presentation?) {
        self.presentAction = presentAction
    }
    
    @MainActor
    public func present() async -> Presentation? {
        let presentation = await presentAction()
        if let presentation {
            status = .presented
            Task {
                while presentation.isDismissed == false {
                    await withCheckedContinuation { continuation in
                        _ = withObservationTracking({ presentation.isDismissed }) {
                            Task(priority: .high) { @MainActor in
                                if await presentation.isDismissed {
                                    self.status = .dismissed
                                }
                                continuation.resume()
                            }
                        }
                    }
                }
            }
        }
        return presentation
    }
}
