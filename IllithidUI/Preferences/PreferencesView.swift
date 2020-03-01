//
// PreferencesView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 12/24/19
//

import SwiftUI

import Illithid

struct PreferencesView: View {
  @ObservedObject var preferences: PreferencesData
  @ObservedObject var accountManager: AccountManager

  var body: some View {
    TabView {
      GeneralPreferences()
        .tabItem {
          Text("General")
        }
      AccountsPreferences(accountManager: accountManager)
        .tabItem {
          Text("Accounts")
        }
    }
    .environmentObject(preferences)
    .frame(minWidth: 300, minHeight: 500)
  }
}

struct GeneralPreferences: View {
  @EnvironmentObject var preferences: PreferencesData

  var body: some View {
    VStack {
      GroupBox(label: Text("Content").font(.headline)) {
        Toggle(isOn: $preferences.hideNsfw) {
          Text("Hide NSFW Content")
        }
      }
      GroupBox(label: Text("Playback").font(.headline)) {
        Toggle(isOn: $preferences.muteAudio) {
          Text("Mute audio content")
        }
      }
      Spacer()
    }
    .frame(alignment: .leading)
  }
}

struct AccountsPreferences: View {
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
      }
      .padding()
    }
  }
}

extension NSImage.Name {
  static let arrowDown = NSImage.Name("arrow-down")
  static let arrowUp = NSImage.Name("arrow-up")
  static let bookmark = NSImage.Name("bookmark")
  static let eyeSlash = NSImage.Name("eye-slash")
  static let flag = NSImage.Name("flag")

  static let checkmark = NSImage.Name("checkmark")

  // Browsers
  static let chrome = NSImage.Name("chrome")
  static let compass = NSImage.Name("compass")
  static let firefox = NSImage.Name("firefox")
  static let safari = NSImage.Name("safari")

  static let redditSquare = NSImage.Name("reddit-square")
}

// #if DEBUG
// struct PreferencesView_Previews: PreviewProvider {
//  static var previews: some View {
//    PreferencesView()
//  }
// }
// #endif
