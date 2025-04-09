import SwiftUI
import SwiftBackports
import Combine

@available(iOS, deprecated: 14.0)
@available(macOS, deprecated: 11.0)
@available(tvOS, deprecated: 14.0)
@available(watchOS, deprecated: 7.0)
public extension Backport where Wrapped: View {

    /// Adds a modifier for this view that fires an action when a specific
    /// value changes.
    ///
    /// `onChange` is called on the main thread. Avoid performing long-running
    /// tasks on the main thread. If you need to perform a long-running task in
    /// response to `value` changing, you should dispatch to a background queue.
    ///
    /// The new value is passed into the closure.
    ///
    /// - Parameters:
    ///   - value: The value to observe for changes
    ///   - action: A closure to run when the value changes.
    ///   - newValue: The new value that changed
    ///
    /// - Returns: A view that fires an action when the specified value changes.
    @ViewBuilder
    func onChange<Value: Equatable>(of value: Value, perform action: @escaping (Value) -> Void) -> some View {
        if #available(iOS 14, tvOS 14, macOS 11, watchOS 7, *) {
            wrapped.onChange(of: value, perform: action)
        } else {
            wrapped.modifier(ChangeModifier(value: value, action: action))
        }
    }

}

public extension Backport where Wrapped: View {
    
    /// Backports iOS 17’s onChange(of:initial:_:) to older OSes.
    ///
    /// - Parameters:
    ///   - value:     The value to observe for changes.
    ///   - initial:   Whether to fire the action as soon as the view appears.
    ///   - action:    Closure receiving `(oldValue, newValue)`.
    /// - Returns: A view that invokes `action` when `value` changes.
    @ViewBuilder
    func onChange<Value: Equatable>(
        of value: Value,
        initial: Bool = false,
        _ action: @escaping (_ oldValue: Value, _ newValue: Value) -> Void
    ) -> some View {
        // If you have SwiftUI from iOS 17 / macOS 14 etc, use the real API:
        if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
            wrapped.onChange(of: value, initial: initial, action)
        }
        // Otherwise, backport it:
        else {
            wrapped.modifier(
                BackportOnChangeModifier(value: value, initial: initial, action: action)
            )
        }
    }
}

/// A fallback for OSes older than iOS 17:
private struct BackportOnChangeModifier<Value: Equatable>: ViewModifier {
    let value: Value
    let initial: Bool
    let action: (Value, Value) -> Void
    
    // We store the "oldValue" so we can pass it to the callback.
    @State private var oldValue: Value
    @State private var didFireInitial = false
    
    init(value: Value, initial: Bool, action: @escaping (Value, Value) -> Void) {
        self.value = value
        self.initial = initial
        self.action = action
        
        // The "oldValue" should be initialized with our current `value`.
        _oldValue = State(wrappedValue: value)
    }
    
    func body(content: Content) -> some View {
        if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
            // For iOS 14+ or macOS 11+, we can rely on .onChange(of:)
            content
                .onAppear {
                    fireInitialIfNeeded()
                }
                .onChange(of: value) { newValue in
                    handleValueChange(newValue)
                }
        } else {
            // Fallback for iOS 13 (or older SwiftUI) with .onReceive:
            content
                .onAppear {
                    fireInitialIfNeeded()
                }
            // We drop the first to avoid "firing" once on init,
            // unless `initial == true`. In that case, we do it
            // inside `fireInitialIfNeeded`.
                .onReceive(Just(value).dropFirst()) { newValue in
                    handleValueChange(newValue)
                }
        }
    }
    
    private func fireInitialIfNeeded() {
        guard initial, !didFireInitial else { return }
        didFireInitial = true
        // For the "initial" call, old==new
        action(value, value)
    }
    
    private func handleValueChange(_ newValue: Value) {
        guard newValue != oldValue else { return }
        let previous = oldValue
        oldValue = newValue
        action(previous, newValue)
    }
}

private struct ChangeModifier<Value: Equatable>: ViewModifier {
    let value: Value
    let action: (Value) -> Void

    @State var oldValue: Value?

    init(value: Value, action: @escaping (Value) -> Void) {
        self.value = value
        self.action = action
        _oldValue = .init(initialValue: value)
    }

    func body(content: Content) -> some View {
        content
            .onReceive(Just(value)) { newValue in
                guard newValue != oldValue else { return }
                action(newValue)
                oldValue = newValue
            }
    }
}
