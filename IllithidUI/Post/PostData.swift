//
// PostData.swift
// Copyright (c) 2019 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import Combine
import SwiftUI

import Illithid

final class PostData: ObservableObject {
  @Published var posts: [Post] = []
}
