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

// MARK: - PagedView

struct PagedView<Data: RandomAccessCollection, ID: Hashable, Content: View>: View {
  // MARK: Lifecycle

  init(data: Data, id: KeyPath<Data.Element, ID>, @ViewBuilder content: @escaping (Data.Element) -> Content) {
    self.data = data
    self.content = content
    self.id = id
    _index = .init(initialValue: data.startIndex)
  }

  // MARK: Internal

  let data: Data
  let id: KeyPath<Data.Element, ID>
  let content: (Data.Element) -> Content

  var body: some View {
    ZStack(alignment: .topTrailing) {
      content(data[index])
        .overlay(
          HStack {
            if index != data.startIndex {
              Button(action: { previous() }, label: { Image(systemName: "chevron.left") })
                .keyboardShortcut(.leftArrow, modifiers: .none)
                .offset(x: 10)
            }
            Spacer()
            Button(action: { next() }, label: {
              Image(systemName: index == data.index(before: data.endIndex) ?
                "arrow.uturn.backward" :
                "chevron.right"
              )
            })
              .keyboardShortcut(.rightArrow, modifiers: .none)
              .offset(x: -10)
          })
        .tag(data[index][keyPath: id])
      Text("\(data.distance(from: data.startIndex, to: index) + 1) / \(data.count)")
        .foregroundColor(.black)
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 8).foregroundColor(.white))
        .padding([.top, .trailing], 10)
        .shadow(radius: 10)
    }
  }

  // MARK: Private

  @State private var index: Data.Index

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

// MARK: - PagedView_Previews

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
