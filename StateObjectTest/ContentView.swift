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
// But If you use ObservedObject in Provider, inside and outside provider count refresh.
// so problem is StateObject.
// the difference of StateObject and ObservedObject is "restore previous value or not"
//
// documentation: https://developer.apple.com/documentation/swiftui/stateobject
// > SwiftUI creates a new instance of the object only once for each instance of the structure that declares the object.
//
// 1. When "count" in ContentView is refreshed, Provider instance is deleted and new Provider instance will be generated (it is SwiftUI's behviour).
// 2. new Provider's init `self._state = StateObject(wrappedValue: state)` works correctly. now, new Provider has new StateObject which have refreshed "count".
// 3. BUT, after 2. new Provider restore and override new StateObject to previous StateObject which have old "count".
// so this is why inside provider count dosen't refresh.
// If you use ObservedObject, it works fine but, ObservedObject is not good for contain state of view.
// workaround is contain StateObject out (but I think it is not smart...)
// the point is dosen't change StateObject's reference which is referenced by Provider
struct RootView: View {
    var body: some View {
        HStack(spacing: 16) {
            // dosen't work
            ContentView(observedType: .stateObject)

            // works
            ContentView(observedType: .observedObject)

            // works
            ContentViewUseStateObjectProviderHasStateObject()
        }
    }
}

final class SubViewState: ObservableObject {
    @Published var count: Int

    init(count: Int) {
        self.count = count
    }
}

struct ContentView: View {
    enum ObservedType {
        case stateObject
        case observedObject
    }

    var observedType: ObservedType

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

            switch observedType {
            case .stateObject:
                StateObjectProvider(state: SubViewState(count: count)) { context in
                    Text("inside: \(context.count)")
                }

                Text("State")
                    .foregroundColor(.red)
            case .observedObject:
                ObserevedObjectProvider(state: SubViewState(count: count)) { context in
                    Text("inside: \(context.count)")
                }

                Text("Observed")
                    .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Use StateObject in Provider

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

// MARK: - Use ObservedObject in Provider

struct ObserevedObjectProvider<Object: ObservableObject, Content: View>: View {
    @ObservedObject private var state: Object
    private var content: (Object) -> Content

    init(state: Object, content: @escaping (Object) -> Content) {
        self._state = ObservedObject(wrappedValue: state)
        self.content = content
    }

    var body: some View {
        content(state)
    }
}

// MARK: - Solution: have state by myself

struct ContentViewUseStateObjectProviderHasStateObject: View {
    // have stateObject
    @StateObject var state = SubViewState(count: 0)

    // some Data such as API Response
    @State var count = Int.random(in: 0...100) {
        didSet {
            // bind to state
            state.count = count
        }
    }

    var body: some View {
        VStack {
            Button {
                count = Int.random(in: 0...100)
            } label: {
                Text("refresh")
            }

            Text("outside: \(count)")

            // pass state
            StateObjectProvider(state: state) { context in
                Text("inside: \(context.count)")
            }

            Text("State+")
                .foregroundColor(.green)
        }
        .onAppear {
            state.count = count
        }
    }
}
