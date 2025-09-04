//
//  MessagePopupView.swift
//  CodeEditorView
//
//  Created by Adrian Russell on 04/09/2025.
//

import SwiftUI
import Combine
import LanguageSupport

struct MessagePopupView: View {
  let messages:    [Message]
  let theme:       Message.Theme
  let invalidated: Bool
  let fixCallback: (Message, Message.Fix) -> Void

  /// The width of the text in the message category with the widest text.
  ///
  @State private var popupWidth: CGFloat?  = nil
  @State private var popupHeight: CGFloat?  = nil

  var body: some View {

    let categories = messagesByCategory(messages)

    VStack(spacing: 4) {
      ForEach(0..<categories.count, id: \.self) { i in
        MessagePopupCategoryView(category: categories[i].0,
                                 messages: categories[i].1,
                                 theme: theme,
                                 invalidated: invalidated,
                                 fixCallback: fixCallback)
      }
    }
    .background(Color.clear)
    .onPreferenceChange(PopupWidth.self) { self.popupWidth = $0 }   // Update the state variable with current width...
    .onPreferenceChange(PopupHeight.self) { self.popupHeight = $0 }   // Update the state variable with current width...
    .environment(\.popupWidth, popupWidth)                          // ...and propagate that value down the view tree.
    .environment(\.popupHeight, popupHeight)                          // ...and propagate that value down the view tree.
  }
    
    
    
    class HostingView: OSView {
        private var hostingView: OSHostingView<MessagePopupView>?

        private let messages:     [Message]
        private let theme:        Message.Theme
        private var background:   Color
        private let fontSize:     CGFloat
        private let colourScheme: ColorScheme
          
//        var unfoldedToggleCallback: ((MessagePopupView.HostingView) -> Void)?
        
        var performMessageFixCallback: ((MessagePopupView.HostingView, Message, Message.Fix) -> Void)?
        
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
             performMessageFixCallback: ((MessagePopupView.HostingView, Message, Message.Fix) -> Void)? = nil)
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
            
            hostingView = OSHostingView(rootView: MessagePopupView(messages: messages,
                                                                   theme: theme,
                                                                   invalidated: invalidated,
                                                                   fixCallback: fixCallback))

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
          self.hostingView?.rootView = MessagePopupView(messages: messages,
                                                        theme: theme,
                                                        invalidated: invalidated,
                                                        fixCallback: fixCallback)
        }
    }
}


/// A view that display all the information of a list of messages.
///
/// NB: The array of messages may not be empty.
///
fileprivate struct MessagePopupCategoryView: View {
  let category:    Message.Category
  let messages:    [Message]
  let theme:       Message.Theme
  let invalidated: Bool
  let fixCallback: (Message, Message.Fix) -> Void

  let cornerRadius: CGFloat = 10

  @Environment(\.colorScheme) private var colourScheme: ColorScheme
  @Environment(\.popupWidth)  private var popupWidth:   CGFloat?
  @Environment(\.popupHeight) private var popupHeight:  CGFloat?

  var body: some View {

    let backgroundColour = colourScheme == .dark ? Color.black : Color.white
    let colour           = if invalidated { Color(OSColor.gray) } else { Color(theme(category).colour) }

    let theActualView =
      HStack(spacing: 0) {

        // Category icon
        ZStack (alignment: .top) {
          colour.opacity(0.5)
          Text("XX")       // We want the icon to have the height of text
            .hidden()
            .overlay( theme(category).icon.frame(alignment: .center) )
            .padding([.leading, .trailing], 5)
            .padding([.top, .bottom], 3)
        }
        .fixedSize(horizontal: true, vertical: false)

        // Vertical stack of message
        VStack(alignment: .leading, spacing: 6) {
          ForEach(0..<messages.count, id: \.self) { i in
            VStack(alignment: .leading) {
              let message = messages[i]
              Text(message.summary)
              if let description = message.description { Text(description) }
              ForEach(0..<message.fixes.count, id: \.self) { fixI in
                let fix = message.fixes[fixI]
                HStack {
                  Spacer()
                    .frame(width: 8)
                  Image(systemName: "bandage")
                  Text(fix.message)
                  Spacer()
                  Button("Fix") {
                    fixCallback(message, fix)
                    // do something
                  }
                  .buttonStyle(FixButtonStyle())
                }
              }
            }
          }
        }
        .padding([.leading, .trailing], 5)
        .padding([.top, .bottom], 3)
//        .frame(maxWidth: popupWidth, maxHeight: popupHeight, alignment: .leading)       // Constrain width if `popupWidth` is not `nil`
        .background(colour.opacity(0.3))
        .background(GeometryReader { proxy in                   // Propagate current width up the view tree
          Color.clear.preference(key: PopupWidth.self, value: proxy.size.width)
          Color.clear.preference(key: PopupHeight.self, value: proxy.size.height)
        })

      }

    // The construction with the overlay is necessary to reliably get the theme colour underneath the
    // category icon to extend to vertically fill the available space. Essentially, the first use of
    // `theActualView` calculates the height, which depends on the vertical stack of messages, and inside
    // the overlay, we then just use the previously calculated height.
    theActualView
    .hidden()
    .overlay(theActualView)
    .background(backgroundColour)
    .cornerRadius(cornerRadius)
    .fixedSize(horizontal: false, vertical: true)           // horizontal must wrap and vertical extend
    .messageBorder(cornerRadius: cornerRadius)
  }
}
