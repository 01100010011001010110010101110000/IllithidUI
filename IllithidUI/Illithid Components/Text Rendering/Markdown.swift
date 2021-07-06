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
import SDWebImageSwiftUI
import SwiftUI

struct Markdown: View {
  // MARK: Lifecycle

  init(mdString: String) {
    self.mdString = mdString
    document = try! Document(text: mdString, options: [.normalize, .noBreaks])
  }

  // MARK: Internal

  let mdString: String

  @ViewBuilder var body: some View {
    ForEach(document.items.indices, id: \.self) { idx in
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
      GroupBox {
        VStack(alignment: .leading) {
          renderChildren(blockQuote.items)
        }
      }
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
      SwiftUI.Text(renderInline(inline: paragraph.items)) +
        SwiftUI.Text("\n")
    }

    func visit(heading: Heading) -> AttributedString {
      var text = renderInline(inline: heading.items)
      switch heading.level {
      case .h1:
        text.font = .system(size: .init(32))
      case .h2:
        text.font = .system(size: .init(24))
      case .h3:
        text.font = .system(size: .init(18.72))
      case .h4:
        text.font = .system(size: .init(16))
      case .h5:
        text.font = .system(size: .init(13.28))
      case .h6:
        text.font = .system(size: .init(10.72))
      default:
        break
      }
      text.inlinePresentationIntent = .stronglyEmphasized
      return text
    }

    func visit(emphasis: Emphasis) -> AttributedString {
      var result = renderInline(inline: emphasis.items)
      result = result.transformingAttributes(AttributeScopes.SwiftUIAttributes.FontAttribute.self) { transformer in
        transformer.value = (transformer.value ?? .body).italic()
      }
      return result
    }

    func visit(strong: Strong) -> AttributedString {
      var result = renderInline(inline: strong.items)
      result = result.transformingAttributes(AttributeScopes.SwiftUIAttributes.FontAttribute.self) { transformer in
        transformer.value = (transformer.value ?? .body).bold()
      }
      return result
    }

    func visit(strikethrough: Strikethrough) -> AttributedString {
      var result = renderInline(inline: strikethrough.items)
      result.swiftUI.strikethroughColor = .primary
      return result
    }

    func visit(rule _: HorizontalRule) -> some View {
      Divider()
        .padding(.vertical)
    }

    func visit(text: Maaku.Text) -> AttributedString {
      AttributedString(text.text)
    }

    func visit(link: Maaku.Link) -> AttributedString {
      var result = renderInline(inline: link.text)
      result.link = URL(string: link.destination!)
      return result
    }

    func visit(lineBreak _: LineBreak) -> AttributedString {
      AttributedString("\n")
    }

    func visit(code: InlineCode) -> AttributedString {
      var result = AttributedString(code.code)
      result.foregroundColor = .orange
      result.inlinePresentationIntent = .code
      return result
    }

    func visit(htmlInline: InlineHtml) -> AttributedString {
      AttributedString(htmlInline.html)
    }

    @ViewBuilder
    func visit(item: ListItem) -> some View {
      let children = item.items
      ForEach(children.indices, id: \.self) { idx in
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
        ForEach(children.indices, id: \.self) { idx in
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
        ForEach(children.indices, id: \.self) { idx in
          MarkdownNode(node: children[idx])
            .environment(\.downListDistance, idx)
        }
      }
      .environment(\.downListType, .unordered)
      .environment(\.downListNestLevel, downListNestLevel + 1)
    }

//    @ViewBuilder
//    func visit(table: Maaku.Table) -> some View {
//      let rows = Array(repeating: GridItem(.flexible()), count: table.rows.count)
//
//      ScrollView {
//        LazyHGrid(rows: rows, content: {
//          renderTableCells(table.header.cells)
//          ForEach(table.rows.indices, id: \.self) { idx in
//            renderTableCells(table.rows[idx].cells)
//          }
//        })
//      }
//    }

//    private func renderTableCells(_ items: [TableCell]) -> some View {
//      ForEach(items.indices, id: \.self) { idx in
//        renderInline(inline: items[idx].items)
//      }
//    }

    func visit(image: Maaku.Image) -> AttributedString {
      var result = renderInline(inline: image.description)
      result.toolTip = image.title
      result.link = image.url
//      result.imageURL = image.url
      return result
    }

    private func renderChildren(_ items: [Node]) -> some View {
      ForEach(items.indices, id: \.self) { idx in
        MarkdownNode(node: items[idx])
      }
    }

    private func renderInline(inline: [Inline]) -> AttributedString {
      var results: [AttributedString] = []
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
        case let node as Maaku.Image:
          return visit(image: node)
        default:
          break
        }
      }
      return results.reduce(AttributedString(), { $0 + $1 })
    }

    private func renderNode(node: Node) -> some View {
      switch node {
      case let node as Inline:
        return SwiftUI.Text(renderInline(inline: [node])).eraseToAnyView()
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
        return SwiftUI.Text(visit(heading: node)).eraseToAnyView()
      case let node as HorizontalRule:
        return visit(rule: node).eraseToAnyView()
//      case let node as Maaku.Table:
//        return visit(table: node).eraseToAnyView()
      default:
        return EmptyView().eraseToAnyView()
      }
    }

    var body: some View {
      renderNode(node: node)
    }
  }

  private var document: Document
}
