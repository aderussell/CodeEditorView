//
//  MessageViews.swift
//  
//
//  Created by Manuel M T Chakravarty on 23/03/2021.
//
//  Defines the visuals that present messages, both inline and as popovers.

import SwiftUI
import Combine
import LanguageSupport


// MARK: -
// MARK: Message category themes

extension Message {

  /// Defines the colours and icons that identify each of the various message categories.
  ///
  typealias Theme = (Message.Category) -> (colour: OSColor, icon: Image)

  /// The default category theme
  ///
  static func defaultTheme(for category: Message.Category) -> (colour: OSColor, icon: Image) {
    switch category {
    case .live:
      return (colour: OSColor.green, icon: Image(systemName: "line.horizontal.3"))
    case .error:
      return (colour: OSColor.red, icon: Image(systemName: "xmark.octagon.fill"))
    case .hole:
      return (colour: OSColor.orange, icon: Image(systemName: "questionmark.circle.fill"))
    case .warning:
      return (colour: OSColor.yellow, icon: Image(systemName: "exclamationmark.triangle.fill"))
    case .informational:
      return (colour: OSColor.cyan, icon: Image(systemName: "info.circle.fill"))
    }
  }
}




// MARK: -
// MARK: Popup view


/// Key to track the width for a set of message popup views.
///
struct PopupWidth: PreferenceKey, EnvironmentKey {

  static let defaultValue: CGFloat? = nil
  static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
    if let nv = nextValue() { value = value.flatMap{ max(nv, $0) } ?? nv }
  }
}

struct PopupHeight: PreferenceKey, EnvironmentKey {

  static let defaultValue: CGFloat? = nil
  static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
    if let nv = nextValue() { value = value.flatMap{ max(nv, $0) } ?? nv }
  }
}

/// Accessor for the environment value identified by the key.
///
extension EnvironmentValues {
  var popupWidth: CGFloat? {
    get { self[PopupWidth.self] }
    set { self[PopupWidth.self] = newValue }
  }
}

extension EnvironmentValues {
  var popupHeight: CGFloat? {
    get { self[PopupHeight.self] }
    set { self[PopupHeight.self] = newValue }
  }
}

struct MessageBorder: ViewModifier {
  let cornerRadius: CGFloat

  @Environment(\.colorScheme) private var colourScheme: ColorScheme

  func body(content: Content) -> some View {

    let shadowColour = colourScheme == .dark ? Color(.sRGBLinear, white: 0, opacity: 0.66)
                                             : Color(.sRGBLinear, white: 0, opacity: 0.33)

    if colourScheme == .dark {
      return AnyView(content
                      .shadow(color: shadowColour, radius: 2, y: 2)
                      .overlay(RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1))
                      .padding(1)
                      .overlay(RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(Color.black, lineWidth: 1)))
    } else {
      return AnyView(content
                      .shadow(color: shadowColour, radius: 1, y: 1)
                      .overlay(RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(Color.black.opacity(0.2), lineWidth: 1)))
    }
  }
}

extension View {

  func messageBorder(cornerRadius: CGFloat) -> some View {
    modifier(MessageBorder(cornerRadius: cornerRadius))
  }
}


// MARK: -
// MARK: Combined view

/// SwiftUI view that displays an array of messages that lie on the same line. It supports switching between an inline
/// format and a full popup format by clicking/tapping on the message.
///
struct MessageView: View {
  struct Geometry {

    /// The maximum width that the inline view may use.
    ///
    let lineWidth:   CGFloat

    /// The height of the inline view
    ///
    let lineHeight:  CGFloat

    /// The maximum width that the popup view may use.
    ///
    let popupWidth:  CGFloat

    /// The distance from the top where the popup view must be placed.
    ///
    let popupOffset: CGFloat
  }

  let messages:    [Message]        // The array of messages that are displayed by this view
  let theme:       Message.Theme    // The message display theme to use
  let background:  Color
  let geometry:    Geometry
  let invalidated: Bool
  let fixCallback: (Message, Message.Fix) -> Void

  @Binding var unfolded: Bool       // False => inline view; true => popup view

  var body: some View {

    // Overlaying the two different views (and switching between them by adjusting their opacity ensures that the view
    // is always sized the same and such that it can accomodate both modes).
    ZStack(alignment: .topTrailing) {

      // We adjust the position of the popup with spacers to ensure that the view frame extends appropriately (this
      // would not be the case if we used `.offset(x:y:)`).
      VStack {
        Spacer(minLength: geometry.popupOffset)
        HStack {
          MessagePopupView(messages: messages, theme: theme, invalidated: invalidated, fixCallback: fixCallback)
            .frame(maxWidth: geometry.popupWidth)
            .onTapGesture { unfolded.toggle() }
          Spacer(minLength: MessageView.popupRightSideOffset)
        }
      }
      .opacity(unfolded ? 1.0 : 0.0)

      MessageInlineView(messages: messages, theme: theme, background: background, invalidated: invalidated)
        .frame(minWidth: MessageView.minimumInlineWidth, maxWidth: geometry.lineWidth, maxHeight: geometry.lineHeight)
        .transition(.opacity)
        .onTapGesture { unfolded.toggle() }
        .animation(.easeInOut(duration: 0.3)) { content in
          content
            .opacity(unfolded ? 0.0 : 1.0)
        }

    }
  }
}

extension MessageView {

  // FIXME: This should maybe depend on the font size and may need to be configurable.
  static let minimumInlineWidth = CGFloat(60)

  /// The distance of the popup view from the right side of the text container.
  ///
  static let popupRightSideOffset = CGFloat(20)
}


// MARK: -
// MARK: Stateful combined view

/// SwiftUI view that displays an array of messages that lie on the same line. It supports switching between an inline
/// and popup view by tapping.
///
struct StatefulMessageView: View {
  let messages:     [Message]              // The array of messages that are displayed by this view
  let theme:        Message.Theme          // The message display theme to use
  let geometry:     MessageView.Geometry   // The geometry constrains for the view
  let background:   Color                  // The background colour
  let fontSize:     CGFloat                // Font size to use for messages
  let colourScheme: ColorScheme            // The colour scheme to use for SwiftUI elements
  let invalidated:  Bool                   // Whether the messages are to be rendered invalidated
  let performMessageFixCallback: (Message, Message.Fix) -> Void

  @ObservedObject var unfolded: ObservableBool  // `true` if the view shows the popup flavour

  /// The unfolding state needs to be communicated between the SwiftUI view and the external world. Hence, we need to
  /// go via an `ObservableObject`.
  ///
  class ObservableBool: ObservableObject {
    @Published var bool: Bool

    init(bool: Bool) {
      self.bool = bool
    }
  }

  var body: some View {
    MessageView(messages: messages,
                theme: theme, 
                background: background,
                geometry: geometry,
                invalidated: invalidated,
                fixCallback: performMessageFixCallback,
                unfolded: $unfolded.bool)
      .font(.system(size: fontSize))
      .environment(\.colorScheme, colourScheme)
      .fixedSize()    // to enforce intrinsic size in the encapsulating `NSHostingView`
  }
}

extension StatefulMessageView {
    
    typealias HostingView = MessageOuterView

//  class HostingView: OSView {
//    private var hostingView: OSHostingView<StatefulMessageView>?
//
//    private let messages:     [Message]
//    private let theme:        Message.Theme
//    private var background:   Color
//    private let fontSize:     CGFloat
//    private let colourScheme: ColorScheme
//      
//    var unfoldedToggleCallback: ((StatefulMessageView.HostingView) -> Void)?
//    
//    var performMessageFixCallback: ((StatefulMessageView.HostingView, Message, Message.Fix) -> Void)?
//    
//    private func fixCallback(_ message: Message, _ fix: Message.Fix) {
//      performMessageFixCallback?(self, message, fix)
//    }
//
//    /// Unfolding status as sharable state.
//    ///
//    private let unfoldedState = StatefulMessageView.ObservableBool(bool: false)
//
//    var geometry: MessageView.Geometry {
//      didSet { reconfigure() }
//    }
//
//    var unfolded: Bool {
//      get { unfoldedState.bool }
//      set { unfoldedState.bool = newValue }
//    }
//
//    var invalidated: Bool {
//      didSet { reconfigure() }
//    }
//    
//    private var cancellables: [AnyCancellable] = []
//
//    init(messages: [Message],
//         theme: @escaping Message.Theme,
//         background: Color,
//         geometry: MessageView.Geometry,
//         fontSize: CGFloat,
//         colourScheme: ColorScheme,
//         unfoldedToggleCallback: ((StatefulMessageView.HostingView) -> Void)? = nil,
//         performMessageFixCallback: ((StatefulMessageView.HostingView, Message, Message.Fix) -> Void)? = nil)
//    {
//      self.messages     = messages
//      self.theme        = theme
//      self.background   = background
//      self.geometry     = geometry
//      self.fontSize     = fontSize
//      self.colourScheme = colourScheme
//      self.invalidated  = false
//      self.unfoldedToggleCallback = unfoldedToggleCallback
//      self.performMessageFixCallback = performMessageFixCallback
//      super.init(frame: .zero)
//
//#if os(iOS) || os(visionOS)
//      isOpaque = false
//#endif
//      translatesAutoresizingMaskIntoConstraints = false
//
//      hostingView = OSHostingView(rootView: StatefulMessageView(messages: messages,
//                                                                theme: theme,
//                                                                geometry: geometry,
//                                                                background: background,
//                                                                fontSize: fontSize,
//                                                                colourScheme: colourScheme,
//                                                                invalidated: invalidated,
//                                                                performMessageFixCallback: fixCallback,
//                                                                unfolded: unfoldedState))
//      unfoldedState.$bool.sink { [weak self] isUnfolded in
//        guard let self else { return }
//        if isUnfolded {
//          unfoldedToggleCallback?(self)
//          superview?.bringSubviewToFront(self)
//        }
//      }.store(in: &cancellables)
//      
//#if os(iOS) || os(visionOS)
//      hostingView?.isOpaque = false
//#endif
//      hostingView?.translatesAutoresizingMaskIntoConstraints = false
//      if let view = hostingView {
//
//        addSubview(view)
//        let constraints = [
//          view.topAnchor.constraint(equalTo: self.topAnchor),
//          view.bottomAnchor.constraint(equalTo: self.bottomAnchor),
//          view.leftAnchor.constraint(equalTo: self.leftAnchor),
//          view.rightAnchor.constraint(equalTo: self.rightAnchor)
//        ]
//        NSLayoutConstraint.activate(constraints)
//
//      }
//    }
//
//    @objc required dynamic init?(coder aDecoder: NSCoder) {
//      fatalError("init(coder:) has not been implemented")
//    }
//
//    private func reconfigure() {
//      self.hostingView?.rootView = StatefulMessageView(messages: messages,
//                                                       theme: theme,
//                                                       geometry: geometry,
//                                                       background: background,
//                                                       fontSize: fontSize,
//                                                       colourScheme: colourScheme,
//                                                       invalidated: invalidated,
//                                                       performMessageFixCallback: fixCallback,
//                                                       unfolded: unfoldedState)
//    }
//  }
}


// MARK: -
// MARK: Previews

let message1 = Message(category: .error, length: 1, summary: "It's wrong!", description: nil),
    message2 = Message(category: .error, length: 1, summary: "Need to fix this.", description: nil),
    message3 = Message(category: .warning, length: 1, summary: "Looks dodgy.",
                       description: AttributedString("This doesn't seem right and also totally unclear " +
                                                        "what it is supposed to do.")),
    message4 = Message(category: .live, length: 1, summary: "Thread 1", description: nil),
    message5 = Message(category: .informational, length: 1, summary: "Cool stuff!", description: nil)

struct MessageViewPreview: View {
  let messages:    [Message]
  let theme:       Message.Theme
  let background:  Color
  let geometry:    MessageView.Geometry

  @State private var unfolded: Bool = false

  var body: some View {
    MessageView(messages: messages,
                theme: theme, 
                background: background,
                geometry: geometry, 
                invalidated: false,
                fixCallback: {_,_ in},
                unfolded: $unfolded)
  }
}

struct MessageViews_Previews: PreviewProvider {

  static var previews: some View {
    let darkBackground  = Color(Theme.defaultDark.backgroundColour)
    let lightBackground = Color(Theme.defaultLight.backgroundColour)

    // Inline view

    MessageInlineView(messages: [message1], theme: Message.defaultTheme, background: darkBackground, invalidated: false)
      .frame(width: 80, height: 15, alignment: .center)
      .preferredColorScheme(.dark)

    MessageInlineView(messages: [message1], theme: Message.defaultTheme, background: darkBackground, invalidated: false)
      .frame(width: 80, height: 25, alignment: .center)
      .preferredColorScheme(.dark)

    VStack{

      MessageInlineView(messages: [message1, message2], theme: Message.defaultTheme, background: darkBackground, invalidated: false)
        .frame(width: 180, height: 15, alignment: .center)
        .preferredColorScheme(.dark)

      MessageInlineView(messages: [message1, message2, message3],
                        theme: Message.defaultTheme,
                        background: darkBackground,
                        invalidated: false)
        .frame(width: 180, height: 15, alignment: .center)
        .preferredColorScheme(.dark)

    }

    MessageInlineView(messages: [message1, message2, message3],
                      theme: Message.defaultTheme,
                      background: lightBackground,
                      invalidated: false)
      .frame(width: 180, height: 15, alignment: .center)
      .preferredColorScheme(.light)

    // Popup view

    MessagePopupView(messages: [message1], theme: Message.defaultTheme, invalidated: false, fixCallback: {_,_ in})
      .font(.system(size: 32))
      .frame(maxWidth: 320, minHeight: 15)
      .preferredColorScheme(.dark)

    MessagePopupView(messages: [message1, message4], theme: Message.defaultTheme, invalidated: false, fixCallback: {_,_ in})
      .frame(maxWidth: 320, minHeight: 15)
      .preferredColorScheme(.dark)

    MessagePopupView(messages: [message1, message2, message3], theme: Message.defaultTheme, invalidated: false, fixCallback: {_,_ in})
      .frame(maxWidth: 320, minHeight: 15)
      .preferredColorScheme(.dark)

    MessagePopupView(messages: [message1, message5, message2, message4, message3],
                     theme: Message.defaultTheme,
                     invalidated: false,
                     fixCallback: {_,_ in})
      .frame(maxWidth: 320, minHeight: 15)
      .preferredColorScheme(.dark)

    MessagePopupView(messages: [message1, message5, message2, message4, message3],
                     theme: Message.defaultTheme,
                     invalidated: false,
                     fixCallback: {_,_ in})
      .frame(maxWidth: 320, minHeight: 15)
      .preferredColorScheme(.light)

    // Combined view

    ZStack(alignment: .topTrailing) {

      Rectangle()
        .foregroundColor(Color.red.opacity(0.1))
        .frame(height: 30)
      HStack { Text("main = putStrLn \"Hello World!\""); Spacer() }
      StatefulMessageView(messages: [message1, message5, message2, message4, message3],
                          theme: Message.defaultTheme,
                          geometry: MessageView.Geometry(lineWidth: 150,
                                                         lineHeight: 15,
                                                         popupWidth: 300,
                                                         popupOffset: 30), 
                          background: darkBackground,
                          fontSize: 15,
                          colourScheme: .dark,
                          invalidated: false,
                          performMessageFixCallback: {_,_ in},
                          unfolded: StatefulMessageView.ObservableBool(bool: false))
        .offset(y: 18)
    }
    .frame(width: 400, height: 300, alignment: .topTrailing)
//    .preferredColorScheme(.light)

  }
}


struct FixButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundStyle(.white)
      .padding(.vertical, 2)
      .padding(.horizontal, 8)
      .background(Color(white: 0.22))
      .brightness(configuration.isPressed ? 0.3 : 0.0)
      .cornerRadius(6)
  }
}


class MessageOuterView: OSView {
    var popup: MessagePopupView.HostingView!
    var inline: MessageInlineView.HostingView!
    
    var geometry: MessageView.Geometry {
      didSet { reconfigure() }
    }
    
    init(messages: [Message],
         theme: @escaping Message.Theme,
         background: Color,
         geometry: MessageView.Geometry,
         fontSize: CGFloat,
         colourScheme: ColorScheme,
         unfoldedToggleCallback: ((MessageOuterView) -> Void)? = nil,
         performMessageFixCallback: ((MessageOuterView, Message, Message.Fix) -> Void)? = nil)
    {
        print(geometry)
        self.geometry = geometry
        super.init(frame: .zero)
        self.translatesAutoresizingMaskIntoConstraints = false
        
        let popup = MessagePopupView.HostingView(messages: messages,
                                                 theme: theme,
                                                 background: background,
                                                 geometry: geometry,
                                                 fontSize: fontSize,
                                                 colourScheme: colourScheme) { _, message, fix in
            performMessageFixCallback?(self, message, fix)
        }
        self.popup = popup
        
        let inline = MessageInlineView.HostingView(messages: messages,
                                                   theme: theme,
                                                   background: background,
                                                   geometry: geometry,
                                                   fontSize: fontSize,
                                                   colourScheme: colourScheme) { _, message, fix in
            performMessageFixCallback?(self, message, fix)
        }
        self.inline = inline
        
        prepareView()
    }
    
    
    
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var customConstaints: [NSLayoutConstraint] = []
    
    func prepareView() {
        addSubview(popup)
        addSubview(inline)
        
        #if canImport(UIKit)
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        inline.addGestureRecognizer(tap)
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        popup.addGestureRecognizer(tap2)
        #endif
        #if canImport(AppKit)
        let tap = NSClickGestureRecognizer(target: self, action: #selector(handleTap))
        inline.addGestureRecognizer(tap)
        let tap2 = NSClickGestureRecognizer(target: self, action: #selector(handleTap))
        popup.addGestureRecognizer(tap2)
        #endif
        
        let constraints = [
            popup.topAnchor.constraint(equalTo: topAnchor, constant: geometry.popupOffset),
            popup.widthAnchor.constraint(equalToConstant: geometry.popupWidth),
            popup.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -MessageView.popupRightSideOffset),
            popup.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            inline.topAnchor.constraint(equalTo: topAnchor),
            inline.trailingAnchor.constraint(equalTo: trailingAnchor),
            inline.widthAnchor.constraint(greaterThanOrEqualToConstant: MessageView.minimumInlineWidth),
            inline.widthAnchor.constraint(lessThanOrEqualToConstant: geometry.lineWidth),
            inline.heightAnchor.constraint(equalToConstant: geometry.lineHeight),
            
            widthAnchor.constraint(greaterThanOrEqualTo: popup.widthAnchor),
            widthAnchor.constraint(greaterThanOrEqualTo: inline.widthAnchor),
//            inline.bottomAnchor.constraint(equalTo: bottomAnchor),
        ]
        
        NSLayoutConstraint.activate(constraints)
        customConstaints = constraints
        
        popup.isHidden = true
    }
    
    @objc func handleTap() {
        unfolded.toggle()
    }
    
    func reconfigure() {
        popup.geometry = geometry
        inline.geometry = geometry
        print(geometry)
        
        NSLayoutConstraint.deactivate(customConstaints)
        let constraints = [
            popup.topAnchor.constraint(equalTo: topAnchor, constant: geometry.popupOffset),
            popup.widthAnchor.constraint(equalToConstant: geometry.popupWidth),
            popup.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -MessageView.popupRightSideOffset),
            popup.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            inline.topAnchor.constraint(equalTo: topAnchor),
            inline.trailingAnchor.constraint(equalTo: trailingAnchor),
            inline.widthAnchor.constraint(greaterThanOrEqualToConstant: MessageView.minimumInlineWidth),
            inline.widthAnchor.constraint(lessThanOrEqualToConstant: geometry.lineWidth),
            inline.heightAnchor.constraint(equalToConstant: geometry.lineHeight),
            
            widthAnchor.constraint(greaterThanOrEqualTo: popup.widthAnchor),
            widthAnchor.constraint(greaterThanOrEqualTo: inline.widthAnchor),
//            inline.bottomAnchor.constraint(equalTo: bottomAnchor),
        ]
        
        NSLayoutConstraint.activate(constraints)
        customConstaints = constraints
    }
    
    var unfolded: Bool = false {
        didSet {
            popup.isHidden = !unfolded
        }
    }

    var invalidated: Bool = false {
      didSet { reconfigure() }
    }
    
    #if canImport(UIKit)
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view == self { return nil }
        return view
    }
    #endif
}
