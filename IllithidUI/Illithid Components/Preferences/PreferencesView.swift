//
// PreferencesView.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 8/1/20
//

import SwiftUI

import Illithid

struct PreferencesView: View {
  @ObservedObject var accountManager: AccountManager

  @State private var preferencePage: PreferencePage = .general

  var body: some View {
    VStack {
      switch preferencePage {
      case .general:
        GeneralPreferences()
          .navigationTitle("General")
      case .accounts:
        AccountsPreferences(accountManager: accountManager)
          .navigationTitle("Accounts")
      }
    }
    .padding(.top, 20)
    .frame(minWidth: 550, maxWidth: 550, maxHeight: 800)
    .toolbar {
      ToolbarItem(placement: .navigation) {
        PreferencesToolbarItemView(selection: $preferencePage, page: .general)
      }

      ToolbarItem(placement: .navigation) {
        PreferencesToolbarItemView(selection: $preferencePage, page: .accounts)
      }
    }
  }
}

private struct PreferencesToolbarItemView: View {
  @Binding var selection: PreferencesView.PreferencePage
  @State private var hovering: Bool = false

  let page: PreferencesView.PreferencePage

  var iconColor: Color {
    if selection == page, hovering { return Color(.cyan) }
    if selection == page { return .blue }
    if hovering { return .white }
    return .gray
  }

  var body: some View {
    VStack(spacing: 1) {
      Image(systemName: page.iconName)
        .foregroundColor(iconColor)
        .font(.title2)
        .onHover { hovering in
          self.hovering = hovering
        }

      Text(page.rawValue.capitalized)
        .font(.body)
    }
    .padding(4)
    .onTapGesture {
      selection = page
    }
    .overlay(RoundedRectangle(cornerRadius: 8).foregroundColor(page == selection ? .white : .clear).opacity(0.2))
  }
}

extension PreferencesView {
  enum PreferencePage: String, Identifiable, CaseIterable {
    var id: String {
      rawValue
    }

    var iconName: String {
      switch self {
      case .general:
        return "gearshape"
      case .accounts:
        return "person.crop.circle"
      }
    }

    case general
    case accounts
  }
}

struct GeneralPreferences: View {
  @ObservedObject var preferences: PreferencesData = .shared

  var body: some View {
    VStack(alignment: .leading) {
      GroupBox(label: Text("Content").font(.headline)) {
        VStack(alignment: .leading) {
          Toggle(isOn: $preferences.hideNsfw) {
            Text("Hide NSFW content")
          }

          Toggle(isOn: $preferences.blurNsfw) {
            Text("Blur NSFW content")
          }

          Picker(selection: $preferences.browser, label: Text("Open links with:")) {
            ForEach(Browser.installed.sorted()) { browser in
              HStack {
                if let icon = browser.icon() {
                  Image(nsImage: icon)
                    .resizable()
                    .frame(width: 16, height: 16)
                }
                Text(browser.displayName!)
              }
              .tag(browser)
            }
          }
          .frame(width: 400)

          Toggle(isOn: $preferences.openLinksInForeground) {
            Text("Open links in foreground")
          }
        }
      }

      GroupBox(label: Text("Playback").font(.headline)) {
        VStack(alignment: .leading) {
          Toggle(isOn: $preferences.muteAudio) {
            Text("Mute audio content")
          }
          Toggle(isOn: $preferences.autoPlayGifs) {
            Text("Auto play GIFs")
          }
        }
      }
      Spacer()
    }
  }
}

func openLink(_ link: URL) {
  let preferences: PreferencesData = .shared

  let toOpen = preferences.browser.bundle == Bundle.main ? URL(string: "illithid://open-url?url=\(link.absoluteString)")! : link

  NSWorkspace.shared.open([toOpen],
                          withApplicationAt: preferences.browser.bundle.bundleURL,
                          configuration: .linkConfiguration)
}

struct AccountsPreferences: View {
  @ObservedObject var accountManager: AccountManager

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      List {
        ForEach(accountManager.accounts) { account in
          HStack {
            if let currentAccount = accountManager.currentAccount, currentAccount.id == account.id {
              Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.green)
            }
            if accountManager.isAuthenticated(account) {
              Text(account.name)
                .onTapGesture { accountManager.setAccount(account) }
            } else {
              Text(account.name)
                .foregroundColor(.red)
              Spacer()
              Button(action: { accountManager.reauthenticate(account: account, anchor: NSApp.keyWindow!) }) {
                Text("Renew Credentials")
              }
            }
          }
          .animation(.spring())
        }
        .onDelete(perform: { accountManager.removeAccounts(indexSet: $0) })
        .padding()
      }
      HStack {
        Button(action: {
          accountManager.addAccount(anchor: NSApp.keyWindow!)
        }) { Text("Add account") }
        Spacer()
        Button(action: {
          accountManager.removeAll()
        }) { Text("Remove all accounts") }
      }
      .padding()
    }
  }
}

final class PreferencesData: ObservableObject, Codable {
  @Published fileprivate(set) var hideNsfw: Bool {
    didSet {
      updateDefaults()
    }
  }

  @Published fileprivate(set) var blurNsfw: Bool {
    didSet {
      updateDefaults()
    }
  }

  // MARK: Playback

  @Published fileprivate(set) var muteAudio: Bool {
    didSet {
      updateDefaults()
    }
  }

  @Published fileprivate(set) var autoPlayGifs: Bool {
    didSet {
      updateDefaults()
    }
  }

  @Published fileprivate(set) var openLinksInForeground: Bool {
    didSet {
      updateDefaults()
    }
  }

  @Published fileprivate(set) var browser: Browser {
    didSet {
      updateDefaults()
    }
  }

  enum CodingKeys: CodingKey {
    case hideNsfw
    case blurNsfw
    case muteAudio
    case autoPlayGifs
    /// Which `Browser` to use for Links
    case browser
    case openLinksInForeground
  }

  private init() {
    hideNsfw = false
    blurNsfw = true
    muteAudio = true
    autoPlayGifs = false
    openLinksInForeground = true
    browser = .inApp
  }

  static let shared: PreferencesData = {
    if let data = UserDefaults.standard.data(forKey: "preferences"),
      let value = try? JSONDecoder().decode(PreferencesData.self, from: data) {
      return value
    } else {
      return .init()
    }
  }()

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    hideNsfw = try (container.decodeIfPresent(Bool.self, forKey: .hideNsfw) ?? false)
    blurNsfw = try (container.decodeIfPresent(Bool.self, forKey: .blurNsfw) ?? true)
    muteAudio = try (container.decodeIfPresent(Bool.self, forKey: .muteAudio) ?? true)
    autoPlayGifs = try (container.decodeIfPresent(Bool.self, forKey: .autoPlayGifs) ?? false)
    browser = try (container.decodeIfPresent(Browser.self, forKey: .browser) ?? .inApp)
    openLinksInForeground = try (container.decodeIfPresent(Bool.self, forKey: .openLinksInForeground) ?? true)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(hideNsfw, forKey: .hideNsfw)
    try container.encode(blurNsfw, forKey: .blurNsfw)
    try container.encode(muteAudio, forKey: .muteAudio)
    try container.encode(autoPlayGifs, forKey: .autoPlayGifs)
    try container.encode(browser, forKey: .browser)
    try container.encode(openLinksInForeground, forKey: .openLinksInForeground)
  }

  private func updateDefaults() {
    guard let data = try? JSONEncoder().encode(self) else {
      // TODO: Error logging
      return
    }

    UserDefaults.standard.set(data, forKey: "preferences")
  }
}

// struct PreferencesView_Previews: PreviewProvider {
//  static var previews: some View {
//    PreferencesView()
//  }
// }
