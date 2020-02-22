//
// PreferencesView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import SwiftUI

import Illithid

struct PreferencesView: View {
  @ObservedObject var accountManager: AccountManager

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
            if self.accountManager.isAuthenticated(account) {
              Text(account.name)
                .onTapGesture { self.accountManager.setAccount(account) }
            } else {
              Text(account.name)
                .foregroundColor(.red)
              Spacer()
              Button(action: { self.accountManager.reauthenticate(account: account, anchor: NSApp.keyWindow!) }) {
                Text("Renew Credentials")
              }
            }
          }
          .animation(.spring())
        }
        .onDelete(perform: { self.accountManager.removeAccounts(indexSet: $0) })
        .padding()
      }
      HStack {
        Button(action: {
          self.accountManager.addAccount(anchor: NSApp.keyWindow!)
        }) { Text("Add account") }
        Spacer()
        Button(action: {
          self.accountManager.removeAll()
        }) { Text("Remove all accounts") }
      }.padding()
    }.frame(minWidth: 300, minHeight: 500)
  }
}

extension NSImage.Name {
  static let checkmark = NSImage.Name("checkmark")
  static let compass = NSImage.Name("compass")
}

// #if DEBUG
// struct PreferencesView_Previews: PreviewProvider {
//  static var previews: some View {
//    PreferencesView()
//  }
// }
// #endif
