//
//  MessageInlineView.swift
//  CodeEditorView
//
//  Created by Adrian Russell on 04/09/2025.
//

import SwiftUI
import Combine
import LanguageSupport

// MARK: -
// MARK: Inline view

/// A view that summarises the message for a line, such that it can be displayed on the right hand side of the line.
/// The view uses the entire height offered.
///
/// NB: The array of messages may not be empty.
///
struct MessageInlineView: View {
  let messages:    [Message]
  let theme:       Message.Theme
  let background:  Color
  let invalidated: Bool

  var body: some View {

    let categories = messagesByCategory(messages).map{ $0.key }

    GeometryReader { geometryProxy in

      let height = geometryProxy.size.height
      let colour = if invalidated { Color(OSColor.gray) } else { Color(theme(categories[0]).colour) }

      HStack {

        Spacer()

        HStack(alignment: .center, spacing: 0) {

          // Category summary
          HStack(alignment: .center, spacing: 0) {

            // Overall message count
            let count = messages.count
            if count > 1 {
              Text("\(count)")
                .padding([.leading, .trailing], 3)
            }

            // All category icons
            HStack(alignment: .center, spacing: 0) {
              ForEach(0..<categories.count, id: \.self){ i in
                HStack(alignment: .center, spacing: 0) {
                  theme(categories[i]).icon
                    .padding([.leading, .trailing], 2)
                }
              }
            }
            .padding([.leading, .trailing], 2)

          }
          .frame(height: height)
          .background(colour.opacity(0.5))
          .roundedCornersOnTheLeft(cornerRadius: 5)

          // Transparent narrow separator
          Divider()
            .foregroundColor(Color.clear)

          // Topmost message of the highest priority category
          HStack {
            Text(messages.filter{ $0.category == categories[0] }.first?.summary ?? "")
              .padding([.leading, .trailing], 5)
          }
          .frame(height: height)
          .background(colour.opacity(0.5))

        }
        .background(background.roundedCornersOnTheLeft(cornerRadius: 5))
      }
    }
  }
    
    
    class HostingView: OSView {
        private var hostingView: OSHostingView<MessageInlineView>?

        private let messages:     [Message]
        private let theme:        Message.Theme
        private var background:   Color
        private let fontSize:     CGFloat
        private let colourScheme: ColorScheme
          
//        var unfoldedToggleCallback: ((MessagePopupView.HostingView) -> Void)?
        
        var performMessageFixCallback: ((MessageInlineView.HostingView, Message, Message.Fix) -> Void)?
        
        private func fixCallback(_ message: Message, _ fix: Message.Fix) {
          performMessageFixCallback?(self, message, fix)
        }

        /// Unfolding status as sharable state.
        ///
   //     private let unfoldedState = MessagePopupView.ObservableBool(bool: false)

        var geometry: MessageView.Geometry {
          didSet { reconfigure() }
        }

//        var unfolded: Bool {
//          get { unfoldedState.bool }
//          set { unfoldedState.bool = newValue }
//        }

        var invalidated: Bool {
          didSet { reconfigure() }
        }
        
        private var cancellables: [AnyCancellable] = []

        init(messages: [Message],
             theme: @escaping Message.Theme,
             background: Color,
             geometry: MessageView.Geometry,
             fontSize: CGFloat,
             colourScheme: ColorScheme,
//             unfoldedToggleCallback: ((MessagePopupView.HostingView) -> Void)? = nil,
             performMessageFixCallback: ((MessageInlineView.HostingView, Message, Message.Fix) -> Void)? = nil)
        {
          self.messages     = messages
          self.theme        = theme
          self.background   = background
          self.geometry     = geometry
          self.fontSize     = fontSize
          self.colourScheme = colourScheme
          self.invalidated  = false
//          self.unfoldedToggleCallback = unfoldedToggleCallback
          self.performMessageFixCallback = performMessageFixCallback
          super.init(frame: .zero)

    #if os(iOS) || os(visionOS)
          isOpaque = false
    #endif
          translatesAutoresizingMaskIntoConstraints = false
            
            hostingView = OSHostingView(rootView: MessageInlineView(messages: messages,
                                                                    theme: theme,
                                                                    background: background,
                                                                    invalidated: invalidated))

//          hostingView = OSHostingView(rootView: StatefulMessageView(messages: messages,
//                                                                    theme: theme,
//                                                                    geometry: geometry,
//                                                                    background: background,
//                                                                    fontSize: fontSize,
//                                                                    colourScheme: colourScheme,
//                                                                    invalidated: invalidated,
//                                                                    performMessageFixCallback: fixCallback,
//                                                                    unfolded: unfoldedState))
//          unfoldedState.$bool.sink { [weak self] isUnfolded in
//            guard let self else { return }
//            if isUnfolded {
//              unfoldedToggleCallback?(self)
//              superview?.bringSubviewToFront(self)
//            }
//          }.store(in: &cancellables)
          
    #if os(iOS) || os(visionOS)
          hostingView?.isOpaque = false
    #endif
          hostingView?.translatesAutoresizingMaskIntoConstraints = false
          if let view = hostingView {

            addSubview(view)
            let constraints = [
              view.topAnchor.constraint(equalTo: self.topAnchor),
              view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
              view.leftAnchor.constraint(equalTo: self.leftAnchor),
              view.rightAnchor.constraint(equalTo: self.rightAnchor)
            ]
            NSLayoutConstraint.activate(constraints)

          }
        }

        @objc required dynamic init?(coder aDecoder: NSCoder) {
          fatalError("init(coder:) has not been implemented")
        }

        private func reconfigure() {
          self.hostingView?.rootView = MessageInlineView(messages: messages,
                                                         theme: theme,
                                                         background: background,
                                                         invalidated: invalidated)
        }
    }
}
