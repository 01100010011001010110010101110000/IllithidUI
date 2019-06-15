//
//  PreferencesView.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 6/12/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import SwiftUI

import Illithid

struct PreferencesView: View {
  @ObjectBinding var accountManager: AccountManager

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      List {
        ForEach(accountManager.accounts) { account in
          HStack {
            if self.accountManager.currentAccount == account {
              Image(nsImage: NSImage(named: .checkmark)!)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(.green)
            }
            Text(account.name)
          }.animation(.fluidSpring())
            .tapAction { self.accountManager.setCurrentAccount(account: account) }
        }.padding()
          .onDelete(perform: { self.accountManager.removeAccount(indexSet: $0) })
      }
      HStack {
        Button(action: {
          self.accountManager.addAccount {}
        }) { Text("Add Account") }
      }.padding()
    }
  }
}

extension NSImage.Name {
  static let checkmark = NSImage.Name("checkmark")
}

// #if DEBUG
// struct PreferencesView_Previews: PreviewProvider {
//  static var previews: some View {
//    PreferencesView()
//  }
// }
// #endif
