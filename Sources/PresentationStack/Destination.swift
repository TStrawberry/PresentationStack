//
//  Destination.swift
//  PresentationStack
//
//  Created by TangTao on 2026/3/9.
//

import SwiftUI
import NavigationValues


public extension View {
    @ViewBuilder
    func presentationDestination<D, C>(
        for data: D.Type,
        @ViewBuilder destination: @escaping (D) -> C
    ) -> some View where D : Identifiable, C : View {
        self.modifier(DestinationModifier(data: data, destination: destination))
    }
}

struct DestinationModifier<D: Identifiable, C: View>: ViewModifier {
    @Environment(\.screenContext) var screenContext
    
    let data: D.Type
    let destination: (D) -> C
    
    init(data: D.Type, @ViewBuilder destination: @escaping (D) -> C) {
        self.data = data
        self.destination = destination
    }
    
    func body(content: Content) -> some View {
        content
            .onChange(of: ObjectIdentifier(data), initial: true) { _, newValue in
                guard let presentation = screenContext as? Presentation else { return }
                
                presentation.addDestination(data, destination: { value in
                    destination(value)
                        .presentation()
                })
            }
    }
}

struct True: Hashable, Identifiable, CustomStringConvertible {
    var id: True { self }
    
    var description: String { "true" }
}


struct PresentationViewModifier: ViewModifier {
    @Environment(\.screenContext) var screenContext
    @Environment(\.dismiss) var dismiss
    
    @State var presentation = Presentation()
    
    func body(content: Content) -> some View {
        content
            .transformEnvironment(\.screenContext) { _ in
                presentation.dismissAction = dismiss
            }
            .screenContext(presentation)
            .setupPresentations($presentation)
    }
}

extension View {
    func presentation() -> some View {
        modifier(PresentationViewModifier())
    }
}
