//
//  AccountData.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 12/25/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import Combine
import SwiftUI

import Illithid

final class AccountData: ObservableObject {
  @Published private(set) var account: Account?

  init(account: Account?) {
    self.account = account
  }

  convenience init(name: String) {
    self.init(account: nil)
    Account.fetch(name: name) { result in
      switch result {
      case .success(let account):
        self.account = account
      case .failure(let error):
        self.account = nil
        print("Failure fetching account: \(error)")
      }
    }
  }
}
