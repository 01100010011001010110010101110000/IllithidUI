//
//  InformationBarData.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 11/20/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

import Illithid

final class InformationBarData: ObservableObject {
  @Published var subscribedSubreddits: [Subreddit] = []
  @Published var multiReddits: [Multireddit] = []
}
