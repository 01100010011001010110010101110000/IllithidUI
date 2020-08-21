//
// RecursiveView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 8/20/20
//

import SwiftUI

struct RecursiveView<Data: RandomAccessCollection, ID: Hashable, Parent: View, Leaf: View, Footer: View>: View {
  let data: Data
  let idKey: KeyPath<Data.Element, ID>
  let childrenKey: KeyPath<Data.Element, Data?>
  let parentView: (Data.Element) -> Parent
  let leafView: (Data.Element) -> Leaf
  let footerView: (Data.Element) -> Footer

  init(data: Data, id: KeyPath<Data.Element, ID>,
       children: KeyPath<Data.Element, Data?>,
       @ViewBuilder parent: @escaping (Data.Element) -> Parent,
       @ViewBuilder leaf: @escaping (Data.Element) -> Leaf,
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
        FlexibleDisclosureGroup(label: {
          parentView(element)
        }, content: {
          VStack {
            RecursiveView(data: children, id: idKey, children: childrenKey,
                          parent: parentView, leaf: leafView, footer: footerView)
            footerView(element)
          }
        })
      } else {
        leafView(element)
      }
    }
  }
}

extension RecursiveView where Parent == Leaf, Data.Element: Identifiable, ID == Data.Element.ID {
  init(data: Data, children: KeyPath<Data.Element, Data?>,
       @ViewBuilder content: @escaping (Data.Element) -> Parent,
       @ViewBuilder footer: @escaping (Data.Element) -> Footer) {
    self.data = data
    idKey = \.id
    childrenKey = children
    parentView = content
    leafView = content
    footerView = footer
  }
}

struct CollapsedKey: EnvironmentKey {
  static let defaultValue: Bool = false
}

extension EnvironmentValues {
  var collapsed: Bool {
    get {
      self[CollapsedKey.self]
    } set {
      self[CollapsedKey.self] = newValue
    }
  }
}

struct FlexibleDisclosureGroup<Label: View, Content: View>: View {
  @State var collapsed: Bool = false
  let label: () -> Label
  let content: () -> Content

  var body: some View {
    VStack {
      label()
        .environment(\.collapsed, collapsed)
        .onTapGesture {
          withAnimation {
            collapsed.toggle()
          }
        }
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
