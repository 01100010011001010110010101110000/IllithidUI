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

struct RecursiveView<Data: RandomAccessCollection, ID: Hashable, Parent: View, Leaf: View, Footer: View>: View {
  let data: Data
  let idKey: KeyPath<Data.Element, ID>
  let childrenKey: KeyPath<Data.Element, Data?>
  let parentView: (Data.Element, Binding<Bool>) -> Parent
  let leafView: (Data.Element, Binding<Bool>) -> Leaf
  let footerView: (Data.Element) -> Footer

  init(data: Data, id: KeyPath<Data.Element, ID>,
       children: KeyPath<Data.Element, Data?>,
       @ViewBuilder parent: @escaping (Data.Element, Binding<Bool>) -> Parent,
       @ViewBuilder leaf: @escaping (Data.Element, Binding<Bool>) -> Leaf,
       @ViewBuilder footer: @escaping (Data.Element) -> Footer) {
    self.data = data
    idKey = id
    childrenKey = children
    parentView = parent
    leafView = leaf
    footerView = footer
  }

  var body: some View {
    ForEach(data, id: idKey) { element in
      if let children = element[keyPath: childrenKey], !children.isEmpty {
        FlexibleDisclosureGroup(label: { isCollapsed in
          parentView(element, isCollapsed)
        }, content: {
          VStack {
            RecursiveView(data: children, id: idKey, children: childrenKey,
                          parent: parentView, leaf: leafView, footer: footerView)
            footerView(element)
          }
        })
      } else {
        FlexibleDisclosureGroup(label: { isCollapsed in
          leafView(element, isCollapsed)
        }, content: { EmptyView() })
      }
    }
  }
}

extension RecursiveView where Parent == Leaf, Data.Element: Identifiable, ID == Data.Element.ID {
  init(data: Data, children: KeyPath<Data.Element, Data?>,
       @ViewBuilder content: @escaping (Data.Element, Binding<Bool>) -> Parent,
       @ViewBuilder footer: @escaping (Data.Element) -> Footer) {
    self.data = data
    idKey = \.id
    childrenKey = children
    parentView = content
    leafView = content
    footerView = footer
  }
}

struct FlexibleDisclosureGroup<Label: View, Content: View>: View {
  @State var collapsed: Bool = false
  let label: (Binding<Bool>) -> Label
  let content: () -> Content

  var body: some View {
    VStack {
      label($collapsed)
      if !collapsed {
        content()
      }
    }
  }
}

// struct RecursiveView_Previews: PreviewProvider {
//  static var previews: some View {
//      RecursiveView()
//  }
// }
