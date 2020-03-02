//
// PreferencesData.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 03/01/2020
//

import Combine
import Foundation
import SwiftUI

final class PreferencesData: ObservableObject, Codable {
  // TODO: When Swift 5.2 releases, replace this with property wrapper composition
  @Published var hideNsfw: Bool = false {
    didSet {
      updateDefaults()
    }
  }

  @Published var muteAudio: Bool = true {
    didSet {
      updateDefaults()
    }
  }

  enum CodingKeys: CodingKey {
    case hideNsfw
    case muteAudio
  }

  init() {}

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    hideNsfw = try container.decode(Bool.self, forKey: .hideNsfw)
    muteAudio = try container.decode(Bool.self, forKey: .muteAudio)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(hideNsfw, forKey: .hideNsfw)
    try container.encode(muteAudio, forKey: .muteAudio)
  }

  private func updateDefaults() {
    let data = try? JSONEncoder().encode(self)
    UserDefaults.standard.set(data, forKey: "preferences")
  }
}
