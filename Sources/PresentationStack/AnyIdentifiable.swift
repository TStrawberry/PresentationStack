//
//  AnyIdentifiable.swift
//  PresentationStack
//
//  Created by TangTao on 2026/3/9.
//

import Foundation

public struct AnyIdentifiable: Identifiable, Equatable {
    public let base: any Identifiable
    public let id: AnyHashable
    let type: ObjectIdentifier

    init<R: Identifiable>(base: R, id: AnyHashable, type: ObjectIdentifier) {
        self.base = base
        self.id = id
        self.type = type
    }

    init(anyIdentifiable: AnyIdentifiable) {
        self.init(
            base: anyIdentifiable.base,
            id: anyIdentifiable.id,
            type: anyIdentifiable.type
        )
    }

    init<T: Identifiable>(base: T) {
        if let anyIdentifiable = base as? AnyIdentifiable {
            self.init(anyIdentifiable: anyIdentifiable)
        } else {
            self.init(
                base: base,
                id: AnyHashable(base.id),
                type: ObjectIdentifier(T.self)
            )
        }
    }
    
    public static func == (lhs: AnyIdentifiable, rhs: AnyIdentifiable) -> Bool {
        lhs.id == rhs.id
    }
}
