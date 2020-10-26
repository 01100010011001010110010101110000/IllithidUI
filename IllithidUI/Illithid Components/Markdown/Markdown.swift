// Copyright (C) 2020 Tyler Gregory (@01100010011001010110010101110000)
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <http://www.gnu.org/licenses/>.

import SwiftUI

import Down
import SDWebImageSwiftUI

import class Down.Image
import class Down.Link
import class Down.List
import class Down.Text

struct Markdown: View {
  @Environment(\.textModifiers) var textModifiers
  @Environment(\.downListType) var downListType
  @Environment(\.downListDistance) var downListDistance

  // TODO: Fix text nodes and adjacent links being rendered as separate views

  let node: Node

  init(mdString: String) {
    // TODO: This is a memory leak. Need to construct a class to hold the pointer and deallocate it during deinit
    node = try! Down(markdownString: mdString).toAST([.normalize, .safe]).wrap()!
  }

  init(node: Node) {
    self.node = node
  }

  func visit(document: Document) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      eachChildView(node: document)
    }
  }

  func visit(blockQuote: BlockQuote) -> some View {
    eachChildView(node: blockQuote)
  }

  func visit(list: List) -> some View {
    let children = list.children
    return VStack(alignment: .leading, spacing: list.isTight ? 5 : 15) {
      ForEach(0 ..< children.count) { idx in
        Markdown(node: children[idx])
          .environment(\.downListDistance, idx)
      }
    }.environment(\.downListType, list.listType)
  }

  @ViewBuilder
  func visit(item: Item) -> some View {
    let children = item.children
    ForEach(0 ..< children.count) { idx in
      let child = children[idx]
      switch child {
      case let child as Paragraph:
        HStack(spacing: 0) {
          switch downListType {
          case .bullet:
            SwiftUI.Text("\(item.indentation)• ")
          case let .ordered(start):
            SwiftUI.Text("\(item.indentation)\(start + downListDistance). ")
          }
          eachChildView(node: child)
        }
      default:
        eachChildView(node: child)
      }
    }
  }

  func visit(codeBlock: CodeBlock) -> some View {
    GroupBox {
      SwiftUI.Text(codeBlock.literal ?? "")
    }.environment(\.textModifiers, textModifiers.union([.codeBlock]))
  }

  func visit(htmlBlock: HtmlBlock) -> some View {
    eachChildView(node: htmlBlock)
  }

  func visit(customBlock: CustomBlock) -> some View {
    eachChildView(node: customBlock)
  }

  func visit(paragraph: Paragraph) -> some View {
    HStack(spacing: 0) {
      eachChildView(node: paragraph)
      SwiftUI.Text("\n")
    }
  }

  func visit(heading: Heading) -> some View {
    HStack(spacing: 0) {
      eachChildView(node: heading)
        .environment(\.textModifiers,
                     textModifiers.union([.heading(heading.headingLevel)]))
    }
  }

  func visit(thematicBreak _: ThematicBreak) -> some View {
    Divider()
      .padding(.vertical)
  }

  func visit(text: Text) -> some View {
    SwiftUI.Text(text.literal ?? "")
      .rationalizeTextModifiers(modifiers: textModifiers)
  }

  func visit(softBreak _: SoftBreak) -> some View {
    SwiftUI.Text(" ")
  }

  func visit(lineBreak _: LineBreak) -> some View {
    SwiftUI.Text("\n")
  }

  func visit(code: Code) -> some View {
    GroupBox {
      SwiftUI.Text(code.literal ?? "")
        .foregroundColor(.orange)
    }.environment(\.textModifiers, textModifiers.union([.code]))
  }

  func visit(htmlInline: HtmlInline) -> some View {
    eachChildView(node: htmlInline)
  }

  func visit(customInline: CustomInline) -> some View {
    eachChildView(node: customInline)
  }

  func visit(emphasis: Emphasis) -> some View {
    HStack(spacing: 0) {
      eachChildView(node: emphasis)
        .environment(\.textModifiers, textModifiers.union([.emphasis]))
    }
  }

  func visit(strong: Strong) -> some View {
    HStack(spacing: 0) {
      eachChildView(node: strong)
        .environment(\.textModifiers, textModifiers.union([.strong]))
    }
  }

  @ViewBuilder
  func visit(link: Link) -> some View {
    SwiftUI.Text(link.literal ?? "")
      .rationalizeTextModifiers(modifiers: textModifiers)
      .foregroundColor(.blue)
      .onTapGesture {
        if let destination = URL(string: link.url ?? "") {
          openLink(destination)
        }
      }
      .help("\(link.url ?? "")\(link.title != nil ? " -- \(link.title!)" : "")")
  }

  @ViewBuilder
  func visit(image: Image) -> some View {
    if image.url != nil, let url = URL(string: image.url!) {
      WebImage(url: url)
        .help(image.title ?? "")
    } else {
      EmptyView()
    }
  }

  @ViewBuilder var body: some View {
    switch node {
    case let node as Document: visit(document: node)
    case let node as BlockQuote: visit(blockQuote: node)
    case let node as List: visit(list: node)
    case let node as Item: visit(item: node)
    case let node as CodeBlock: visit(codeBlock: node)
    case let node as HtmlBlock: visit(htmlBlock: node)
    case let node as CustomBlock: visit(customBlock: node)
    case let node as Paragraph: visit(paragraph: node)
    case let node as Heading: visit(heading: node)
    case let node as ThematicBreak: visit(thematicBreak: node)
    case let node as Text: visit(text: node)
    case let node as SoftBreak: visit(softBreak: node)
    case let node as LineBreak: visit(lineBreak: node)
    case let node as Code: visit(code: node)
    case let node as HtmlInline: visit(htmlInline: node)
    case let node as CustomInline: visit(customInline: node)
    case let node as Emphasis: visit(emphasis: node)
    case let node as Strong: visit(strong: node)
    case let node as Link: visit(link: node)
    case let node as Image: visit(image: node)
    default:
      EmptyView()
    }
  }

  func eachChildView(node: Node) -> some View {
    let children = node.children
    return ForEach(0 ..< children.count) { idx in
      Markdown(node: children[idx])
    }
  }
}

private extension SwiftUI.Text {
  func rationalizeTextModifiers(modifiers: Set<DownTextModifier>) -> SwiftUI.Text {
    var result = self
    modifiers.forEach { modifier in
      switch modifier {
      case .code:
        break
      case .codeBlock:
        break
      case .emphasis:
        result = result.italic()
      case .strong:
        result = result.bold()
      case let .heading(level):
        result = result.bold()
        switch level {
        case 1:
          result = result.font(.system(size: .init(32)))
        case 2:
          result = result.font(.system(size: .init(24)))
        case 3:
          result = result.font(.system(size: .init(18.72)))
        case 4:
          result = result.font(.system(size: .init(16)))
        case 5:
          result = result.font(.system(size: .init(13.28)))
        case 6:
          result = result.font(.system(size: .init(10.72)))
        default:
          break
        }
      }
    }
    return result
  }
}

private extension Link {
  var literal: String? {
    guard let child = children.first else { return nil }
    switch child {
    case let child as Code:
      return child.literal
    case let child as Text:
      return child.literal
    case let child as CodeBlock:
      return child.literal
    default:
      return nil
    }
  }
}

private extension Item {
  var indentation: String {
    .init(repeating: " ", count: 4 * nestDepth)
  }

  var text: AnyView {
    guard let paragraph = children.first(where: { $0 is Paragraph }) else { return EmptyView().eraseToAnyView() }
    return Markdown(node: paragraph).eraseToAnyView()
  }
}
