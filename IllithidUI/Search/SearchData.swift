//
//  SearchData.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 7/8/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

import Illithid

final class SearchData: ObservableObject {
  @Published var queryResults: Listing? = nil
}
