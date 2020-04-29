//
// LoopedIterator.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 4/28/20
//

import Foundation

extension Collection {
  func makeLoopedIterator() -> AnyIterator<Element> {
    var index = startIndex

    return AnyIterator {
      if self.isEmpty { return nil }

      let result = self[index]
      self.formIndex(after: &index)
      if index == self.endIndex {
        index = self.startIndex
      }

      return result
    }
  }
}
