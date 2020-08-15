//
// SortController.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 7/1/20
//

import SwiftUI

import Illithid

final class SortModel<Sort>: ObservableObject where Sort: RawRepresentable & CaseIterable & Identifiable & Hashable, Sort.RawValue == String, Sort.AllCases: RandomAccessCollection {
  @Published var sort: Sort
  @Published var topInterval: TopInterval

  init(sort: Sort, topInterval: TopInterval) {
    self.sort = sort
    self.topInterval = topInterval
  }
}

struct SortController<Sort>: View where Sort: RawRepresentable & CaseIterable & Identifiable & Hashable, Sort.RawValue == String, Sort.AllCases: RandomAccessCollection {
  @ObservedObject var sortModel: SortModel<Sort>

  init(model: SortModel<Sort>) {
    sortModel = model
  }

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

struct SortController_Previews: PreviewProvider {
  @StateObject private static var model: SortModel<PostSort> = .init(sort: .best, topInterval: .day)

  static var previews: some View {
    SortController(model: model)
  }
}
