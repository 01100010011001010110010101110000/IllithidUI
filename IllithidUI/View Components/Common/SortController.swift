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

import Illithid

// MARK: - SortModel

final class SortModel<Sort>: ObservableObject where Sort: RawRepresentable & CaseIterable & Identifiable & Hashable, Sort.RawValue == String, Sort.AllCases: RandomAccessCollection {
  // MARK: Lifecycle

  init(sort: Sort, topInterval: TopInterval) {
    self.sort = sort
    self.topInterval = topInterval
  }

  // MARK: Internal

  @Published var sort: Sort
  @Published var topInterval: TopInterval
}

// MARK: - SortController

struct SortController<Sort>: View where Sort: RawRepresentable & CaseIterable & Identifiable & Hashable, Sort.RawValue == String, Sort.AllCases: RandomAccessCollection {
  // MARK: Lifecycle

  init(model: SortModel<Sort>) {
    sortModel = model
  }

  // MARK: Internal

  @ObservedObject var sortModel: SortModel<Sort>

  var body: some View {
    HStack {
      Picker(selection: $sortModel.sort, label: EmptyView()) {
        ForEach(Sort.allCases) { sortMethod in
          Text(sortMethod.rawValue).tag(sortMethod)
        }
      }
      .frame(maxWidth: 100)
      if sortModel.sort.rawValue == "top" || sortModel.sort.rawValue == "controversial" {
        Picker(selection: $sortModel.topInterval, label: EmptyView()) {
          ForEach(TopInterval.allCases) { interval in
            Text(interval.rawValue).tag(interval)
          }
        }
        .frame(maxWidth: 100)
      }
      Spacer()
    }
    .padding([.top, .leading, .trailing], 10)
  }
}

// MARK: - SortController_Previews

struct SortController_Previews: PreviewProvider {
  // MARK: Internal

  static var previews: some View {
    SortController(model: model)
  }

  // MARK: Private

  @StateObject private static var model: SortModel<PostSort> = .init(sort: .best, topInterval: .day)
}
