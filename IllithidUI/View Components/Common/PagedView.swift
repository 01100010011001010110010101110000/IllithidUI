//
// PagedView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 8/1/20
//

import SwiftUI

struct PagedView<Data: RandomAccessCollection, ID: Hashable, Content: View>: View {
  @State private var index: Data.Index

  let data: Data
  let id: KeyPath<Data.Element, ID>
  let content: (Data.Element) -> Content

  init(data: Data, id: KeyPath<Data.Element, ID>, @ViewBuilder content: @escaping (Data.Element) -> Content) {
    self.data = data
    self.content = content
    self.id = id
    _index = .init(initialValue: data.startIndex)
  }

  var body: some View {
    ZStack(alignment: .topTrailing) {
      content(data[index])
        .overlay(
          HStack {
            if index != data.startIndex {
              Button(action: { previous() }, label: { Image(systemName: "chevron.left") })
                .offset(x: 10)
            }
            Spacer()
            Button(action: { next() }, label: {
              Image(systemName: index == data.index(before: data.endIndex) ?
                "arrow.uturn.backward" :
                "chevron.right"
              )
            })
              .offset(x: -10)
          })
        .tag(data[index][keyPath: id])
      Text("\(data.distance(from: data.startIndex, to: index) + 1) / \(data.count)")
        .foregroundColor(.black)
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 8).foregroundColor(.white))
        .padding([.top, .trailing], 4)
        .shadow(radius: 10)
    }
  }

  private func next() {
    if index >= data.index(before: data.endIndex) {
      index = data.startIndex
    } else {
      index = data.index(after: index)
    }
  }

  private func previous() {
    if index == data.startIndex {
      index = data.index(before: data.endIndex)
    } else {
      index = data.index(before: index)
    }
  }
}

extension PagedView where Data.Element: Identifiable, ID == Data.Element.ID {
  init(data: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
    self.data = data
    self.content = content
    id = \.id
    _index = .init(initialValue: data.startIndex)
  }
}

struct PagedView_Previews: PreviewProvider {
  static let data: [Int] = [1, 2, 3, 4, 5]

  static var previews: some View {
    PagedView(data: data, id: \.self) { item in
      Rectangle()
        .foregroundColor(.gray)
        .overlay(Text("\(item)"))
        .frame(width: 200, height: 200)
    }
  }
}
