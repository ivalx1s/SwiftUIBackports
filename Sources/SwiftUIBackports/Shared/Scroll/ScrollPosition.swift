import SwiftUI

public extension Backport where Wrapped: View {
    
    /// Backports iOS 17's `scrollPosition(id:anchor:)` to older OS versions.
    ///
    /// - Parameters:
    ///   - id: A binding to the ID of the scroll target that SwiftUI should keep in view.
    ///   - anchor: How you want the identified view aligned when scrolling. Defaults to minimal scrolling.
    /// - Returns: A view that tracks and scrolls to the specified ID.
    @ViewBuilder
    func scrollPosition<ID: Hashable>(
        id: Binding<ID?>,
        anchor: UnitPoint? = nil
    ) -> some View {
        if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, *) {
            wrapped.scrollPosition(id: id, anchor: anchor)
        } else {
            wrapped
        }
    }
}
