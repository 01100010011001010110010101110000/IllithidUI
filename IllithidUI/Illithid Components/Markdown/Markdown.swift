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

import Maaku
import SwiftUI

struct Markdown: View {
  // MARK: Lifecycle

  init(mdString: String) {
    self.mdString = mdString
    _document = .init(initialValue: try! Document(text: mdString, options: [.normalize, .noBreaks]))
  }

  // MARK: Internal

  let mdString: String

  @ViewBuilder var body: some View {
    ForEach(0 ..< document.count) { idx in
      MarkdownNode(node: document.items[idx])
    }
  }

  // MARK: Private

  private struct MarkdownNode: View {
    @Environment(\.downListType) private var downListType
    @Environment(\.downListDistance) private var downListDistance
    @Environment(\.downListNestLevel) private var downListNestLevel

    let node: Node

    func visit(blockQuote: BlockQuote) -> some View {
      renderChildren(blockQuote.items)
    }

    func visit(codeBlock: CodeBlock) -> some View {
      GroupBox {
        SwiftUI.Text(codeBlock.code)
      }
    }

    func visit(htmlBlock: HtmlBlock) -> SwiftUI.Text {
      SwiftUI.Text(htmlBlock.html)
    }

    func visit(paragraph: Paragraph) -> some View {
      HStack(spacing: 0) {
        renderInline(inline: paragraph.items)
        SwiftUI.Text("\n")
      }
    }

    func visit(heading: Heading) -> some View {
      var text = renderInline(inline: heading.items).fontWeight(.semibold)
      switch heading.level {
      case .h1:
        text = text.font(.system(size: .init(32)))
      case .h2:
        text = text.font(.system(size: .init(24)))
      case .h3:
        text = text.font(.system(size: .init(18.72)))
      case .h4:
        text = text.font(.system(size: .init(16)))
      case .h5:
        text = text.font(.system(size: .init(13.28)))
      case .h6:
        text = text.font(.system(size: .init(10.72)))
      default:
        break
      }
      return text
    }

    func visit(emphasis: Emphasis) -> SwiftUI.Text {
      renderInline(inline: emphasis.items)
        .italic()
    }

    func visit(strong: Strong) -> SwiftUI.Text {
      renderInline(inline: strong.items)
        .bold()
    }

    func visit(strikethrough: Strikethrough) -> SwiftUI.Text {
      renderInline(inline: strikethrough.items)
        .strikethrough()
    }

    func visit(rule _: HorizontalRule) -> some View {
      Divider()
        .padding(.vertical)
    }

    func visit(text: Maaku.Text) -> SwiftUI.Text {
      SwiftUI.Text(text.text)
    }

    func visit(link: Maaku.Link) -> SwiftUI.Text {
      renderInline(inline: link.text)
        .foregroundColor(.blue)
    }

    func visit(image _: Maaku.Image) -> some View {
      SwiftUI.Text("I'm an image!")
    }

    func visit(lineBreak _: LineBreak) -> SwiftUI.Text {
      SwiftUI.Text("\n")
    }

    func visit(code: InlineCode) -> SwiftUI.Text {
      SwiftUI.Text(code.code)
        .foregroundColor(.orange)
    }

    func visit(htmlInline: InlineHtml) -> SwiftUI.Text {
      SwiftUI.Text(htmlInline.html)
    }

    @ViewBuilder
    func visit(item: ListItem) -> some View {
      let children = item.items
      ForEach(0 ..< children.count) { idx in
        let child = children[idx]
        switch child {
        case let child as Paragraph:
          HStack(spacing: 0) {
            switch downListType {
            case .unordered:
              SwiftUI.Text("\(String(repeating: " ", count: 4 * downListNestLevel))• ")
            case .ordered:
              SwiftUI.Text("\(String(repeating: " ", count: 4 * downListNestLevel))\(downListDistance + 1). ")
            }
            renderNode(node: child)
          }
        default:
          renderNode(node: child)
        }
      }
    }

    func visit(orderedList: OrderedList) -> some View {
      let children = orderedList.items
      return VStack(alignment: .leading) {
        ForEach(0 ..< children.count) { idx in
          MarkdownNode(node: children[idx])
            .environment(\.downListDistance, idx)
        }
      }
      .environment(\.downListType, .ordered)
      .environment(\.downListNestLevel, downListNestLevel + 1)
    }

    func visit(unorderedList: UnorderedList) -> some View {
      let children = unorderedList.items
      return VStack(alignment: .leading) {
        ForEach(0 ..< children.count) { idx in
          MarkdownNode(node: children[idx])
            .environment(\.downListDistance, idx)
        }
      }
      .environment(\.downListType, .unordered)
      .environment(\.downListNestLevel, downListNestLevel + 1)
    }

    private func renderChildren(_ items: [Node]) -> some View {
      ForEach(0 ..< items.count) { idx in
        MarkdownNode(node: items[idx])
      }
    }

    private func renderInline(inline: [Inline]) -> SwiftUI.Text {
      var results: [SwiftUI.Text] = []
      for node in inline {
        switch node {
        case let node as Maaku.Link:
          results.append(visit(link: node))
        case let node as Maaku.Text:
          results.append(visit(text: node))
        case let node as LineBreak:
          results.append(visit(lineBreak: node))
        case let node as InlineCode:
          results.append(visit(code: node))
        case let node as InlineHtml:
          results.append(visit(htmlInline: node))
        case let node as Emphasis:
          results.append(visit(emphasis: node))
        case let node as Strong:
          results.append(visit(strong: node))
        case let node as Strikethrough:
          results.append(visit(strikethrough: node))
        default:
          break
        }
      }
      return results.reduce(Text(""), { $0 + $1 })
    }

    private func renderNode(node: Node) -> some View {
      switch node {
      case let node as Inline:
        return renderInline(inline: [node]).eraseToAnyView()
      case let node as BlockQuote:
        return visit(blockQuote: node).eraseToAnyView()
      case let node as OrderedList:
        return visit(orderedList: node).eraseToAnyView()
      case let node as UnorderedList:
        return visit(unorderedList: node).eraseToAnyView()
      case let node as ListItem:
        return visit(item: node).eraseToAnyView()
      case let node as CodeBlock:
        return visit(codeBlock: node).eraseToAnyView()
      case let node as HtmlBlock:
        return visit(htmlBlock: node).eraseToAnyView()
      case let node as Paragraph:
        return visit(paragraph: node).eraseToAnyView()
      case let node as Heading:
        return visit(heading: node).eraseToAnyView()
      case let node as HorizontalRule:
        return visit(rule: node).eraseToAnyView()
      case let node as Maaku.Image:
        return visit(image: node).eraseToAnyView()
      default:
        return EmptyView().eraseToAnyView()
      }
    }

    @ViewBuilder var body: some View {
      renderNode(node: node)
    }
  }

  @State private var document: Document
}
