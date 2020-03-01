//
// PreferencesData.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 03/01/2020
//

import Combine
import Foundation
import SwiftUI

final class PreferencesData: ObservableObject {
  @Published var hideNsfw: Bool = false
  @Published var muteAudio: Bool = true
}
