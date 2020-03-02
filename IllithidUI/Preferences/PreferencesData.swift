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

  // MARK: Playback
  @Published var muteAudio: Bool = true {
    didSet {
      updateDefaults()
    }
  }
  @Published var autoPlayGifs: Bool = false {
    didSet {
      updateDefaults()
    }
  }

  enum CodingKeys: CodingKey {
    case hideNsfw
    case muteAudio
    case autoPlayGifs
  }

  init() {}

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    hideNsfw = try container.decode(Bool.self, forKey: .hideNsfw)
    muteAudio = try container.decode(Bool.self, forKey: .muteAudio)
    autoPlayGifs = (try? container.decode(Bool.self, forKey: .autoPlayGifs)) ?? false
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(hideNsfw, forKey: .hideNsfw)
    try container.encode(muteAudio, forKey: .muteAudio)
    try container.encode(autoPlayGifs, forKey: .autoPlayGifs)
  }

  private func updateDefaults() {
    let data = try? JSONEncoder().encode(self)
    UserDefaults.standard.set(data, forKey: "preferences")
  }
}
