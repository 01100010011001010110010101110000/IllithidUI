//
// Post+Comment+DateFormatter.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 5/10/20
//

import Foundation

import Illithid

extension Post {
  public var relativePostTime: String {
    DateComponentsFormatter.ShortFormatter.string(from: createdUtc, to: Date()) ?? "UNKNOWN"
  }

  public var absolutePostTime: String {
    DateFormatter.LongFormatter.string(from: createdUtc)
  }
}

extension Comment {
  public var relativeCommentTime: String {
    DateComponentsFormatter.ShortFormatter.string(from: createdUtc, to: Date()) ?? "UNKNOWN"
  }
}

extension DateComponentsFormatter {
  static let ShortFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.maximumUnitCount = 1
    formatter.unitsStyle = .abbreviated
    formatter.allowsFractionalUnits = true
    formatter.zeroFormattingBehavior = .dropAll
    formatter.allowedUnits = [.month, .day, .hour, .minute, .year]
    return formatter
  }()
}

extension DateFormatter {
  static let LongFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    formatter.timeStyle = .long
    return formatter
  }()
}
