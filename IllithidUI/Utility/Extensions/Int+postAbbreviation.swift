//
// Int+postAbbreviation.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 3/21/20
//

import Foundation

public extension Int {
  func postAbbreviation(_ significantFigures: Int = 1) -> String {
    guard self >= 1000 else { return description }
    let float_self = Double(self)
    let (divisor, unit) = self >= 1_000_000 ? (1_000_000.0, "M") : (1000.0, "k")
    return String(format: "%.\(significantFigures)f\(unit)", float_self / divisor)
  }

  func absoluteDifference(to: Int) -> UInt {
    (self - to).magnitude
  }
}
