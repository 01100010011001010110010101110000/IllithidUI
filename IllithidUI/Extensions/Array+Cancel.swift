//
// Array+Cancel.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 8/1/20
//

import Combine

extension Array where Element: Cancellable {
  /// Removes each element from the array and cancels it, leaving an empty array
  /// - Returns: Void
  mutating func cancel() {
    while !isEmpty {
      popLast()?.cancel()
    }
  }
}
