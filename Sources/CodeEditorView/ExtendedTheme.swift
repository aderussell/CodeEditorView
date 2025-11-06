//
//  ExtendedTheme.swift
//  CodeEditorView
//
//  Created by Adrian Russell on 12/04/2025.
//

import Foundation
import SwiftUI

public struct ExtendedTheme: Identifiable {
  public private(set) var id = UUID()
    
    struct AttributeStyle {
        var color: OSColor
        var fontName: String
        var fontSize: CGFloat
        var bold: Bool = false
        var italics: Bool = false
    }

  /// The colour scheme of the theme.
  ///
  public var colourScheme: ColorScheme {
    didSet { id = UUID() }
  }

  /// The name of the font to use.
  ///
  public var fontName: String {
    didSet { id = UUID() }
  }

  /// The point size of the font to use.
  ///
  public var fontSize: CGFloat {
    didSet { id = UUID() }
  }

  /// The default foreground text colour.
  ///
  public var textColour: OSColor {
    didSet { id = UUID() }
  }

  /// The colour for (all kinds of) comments.
  ///
  public var commentColour: OSColor {
    didSet { id = UUID() }
  }

  /// The colour for string literals.
  ///
  public var stringColour: OSColor {
    didSet { id = UUID() }
  }

  /// The colour for character literals.
  ///
  public var characterColour: OSColor {
    didSet { id = UUID() }
  }

  /// The colour for number literals.
  ///
  public var numberColour: OSColor {
    didSet { id = UUID() }
  }

  /// The colour for identifiers.
  ///
  public var identifierColour: OSColor {
    didSet { id = UUID() }
  }

  /// The colour for operators.
  ///
  public var operatorColour: OSColor {
    didSet { id = UUID() }
  }

  /// The colour for keywords.
  ///
  public var keywordColour: OSColor {
    didSet { id = UUID() }
  }

  /// The colour for reserved symbols.
  ///
  public var symbolColour: OSColor {
    didSet { id = UUID() }
  }

  /// The colour for type names (identifiers and operators).
  ///
  public var typeColour: OSColor {
    didSet { id = UUID() }
  }

  /// The colour for field names.
  ///
  public var fieldColour: OSColor {
    didSet { id = UUID() }
  }

  /// The colour for names of alternatives.
  ///
  public var caseColour: OSColor {
    didSet { id = UUID() }
  }

  /// The background colour.
  ///
  public var backgroundColour: OSColor {
    didSet { id = UUID() }
  }

  /// The colour of the current line highlight.
  ///
  public var currentLineColour: OSColor {
    didSet { id = UUID() }
  }

  /// The colour to use for the selection highlight.
  ///
  public var selectionColour: OSColor {
    didSet { id = UUID() }
  }

  /// The cursor colour.
  ///
  public var cursorColour: OSColor {
    didSet { id = UUID() }
  }

  /// The colour to use if invisibles are drawn.
  ///
  public var invisiblesColour: OSColor {
    didSet { id = UUID() }
  }
   
  /// The spacing between new lines.
  ///
  public var paragraphSpacing: CGFloat {
    didSet { id = UUID() }
  }
  
  /// The spacing between content of a wrapped line.
  ///
  public var lineSpacing: CGFloat {
    didSet { id = UUID() }
  }

  public init(colourScheme: ColorScheme,
              fontName: String,
              fontSize: CGFloat,
              textColour: OSColor,
              commentColour: OSColor,
              stringColour: OSColor,
              characterColour: OSColor,
              numberColour: OSColor,
              identifierColour: OSColor,
              operatorColour: OSColor,
              keywordColour: OSColor,
              symbolColour: OSColor,
              typeColour: OSColor,
              fieldColour: OSColor,
              caseColour: OSColor,
              backgroundColour: OSColor,
              currentLineColour: OSColor,
              selectionColour: OSColor,
              cursorColour: OSColor,
              invisiblesColour: OSColor,
              paragraphSpacing: CGFloat = 0.0,
              lineSpacing: CGFloat = 0.0)
  {
    self.colourScheme = colourScheme
    self.fontName = fontName
    self.fontSize = fontSize
    self.textColour = textColour
    self.commentColour = commentColour
    self.stringColour = stringColour
    self.characterColour = characterColour
    self.numberColour = numberColour
    self.identifierColour = identifierColour
    self.operatorColour = operatorColour
    self.keywordColour = keywordColour
    self.symbolColour = symbolColour
    self.typeColour = typeColour
    self.fieldColour = fieldColour
    self.caseColour = caseColour
    self.backgroundColour = backgroundColour
    self.currentLineColour = currentLineColour
    self.selectionColour = selectionColour
    self.cursorColour = cursorColour
    self.invisiblesColour = invisiblesColour
    self.paragraphSpacing = paragraphSpacing
    self.lineSpacing = lineSpacing
  }
}
