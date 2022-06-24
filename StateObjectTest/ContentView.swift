//
//  ContentView.swift
//  StateObjectTest
//
//  Created by kntk on 2022/04/13.
//

import Foundation
import SwiftUI
import Combine

// If you use StateObject in Provider, "inside provider count" dosen't refresh even "outSide provider count" refreshed.
// problem is StateObject. StateObject is restored as long as View's structure and View's id is not changed.
// documentation: https://developer.apple.com/documentation/swiftui/stateobject
// > SwiftUI creates a new instance of the object only once for each instance of the structure that declares the object.
//
// 1. When "@State var count" in ContentView is refreshed, Provider instance is deleted and new Provider instance will be generated (it is SwiftUI's behviour).
// 2. new Provider's init `self._state = StateObject(wrappedValue: state)` works correctly. now, new Provider has new StateObject which have refreshed "count".
// 3. BUT, after 2. new Provider restore and override new StateObject to previous StateObject which have old "count".
// because of StateObject's behavior so this is why inside provider count dosen't refresh.
//
// Solution: Add id by .id() to Provider
struct RootView: View {
    var body: some View {
        HStack(spacing: 16) {
            // dosen't work
            ContentView(type: .normal)

            // works
            ContentView(type: .addingID)
        }
    }
}

final class SubViewState: ObservableObject {

    private let id = UUID().uuidString

    @Published var count: Int

    init(count: Int) {
        self.count = count
    }
}

struct ContentView: View {
    enum ProviderType: String {
        case normal
        case addingID
    }

    var type: ProviderType

    // some Data such as API Response
    @State var count = Int.random(in: 0...100)

    var body: some View {
        VStack {
            Button {
                count = Int.random(in: 0...100)
            } label: {
                Text("refresh")
            }

            Text("outside: \(count)")

            switch type {
            case .normal:
                StateObjectProvider(state: SubViewState(count: count)) { context in
                    Text("inside: \(context.count)")
                }

                Text(type.rawValue)
                    .foregroundColor(.red)

            case .addingID:
                StateObjectProviderAddingID(state: SubViewState(count: count)) { context in
                    Text("inside: \(context.count)")
                }

                Text(type.rawValue)
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Normal Provider

struct StateObjectProvider<Object: ObservableObject, Content: View>: View {
    @StateObject private var state: Object
    private var content: (Object) -> Content

    init(state: Object, content: @escaping (Object) -> Content) {
        self._state = StateObject(wrappedValue: state)
        self.content = content
    }

    var body: some View {
        content(state)
    }
}

// MARK: - Solution: adding id by .id() to Provider View

extension SubViewState: Hashable {
    static func == (lhs: SubViewState, rhs: SubViewState) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct StateObjectProviderAddingID<Object: ObservableObject & Hashable, Content: View>: View {
    private var state: Object
    private var content: (Object) -> Content

    init(state: Object, content: @escaping (Object) -> Content) {
        self.state = state
        self.content = content
    }

    var body: some View {
        StateObjectProvider(state: state, content: content)
            .id(state.hashValue) // here
    }
}
