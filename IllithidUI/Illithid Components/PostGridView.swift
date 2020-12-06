//
//  PostGridView.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 11/30/20.
//  Copyright © 2020 Tyler Gregory. All rights reserved.
//

import SwiftUI

import Illithid

struct PostGridView: View {
  @StateObject private var informationBarData: InformationBarData = .init()
  @State private var columns: [UUID] = [UUID()]
  @StateObject private var columnManager: ColumnManager = ColumnManager()

  var body: some View {
    ZStack(alignment: .bottomTrailing) {
      HStack {
        HSplitView {
          ForEach(columnManager.columns.indices, id: \.self) { idx in
            SubredditSelectorView(column: $columnManager.columns[idx], onExit: { columnManager.removeColumn(id: $0) })
              .environmentObject(informationBarData)
              .environmentObject(columnManager)
              .frame(minWidth: 300)
          }
        }
        Spacer()
      }
      Button(action: {
        columnManager.addColumn()
      }, label: {
        Image(systemName: "plus")
      })
      .keyboardShortcut(.rightArrow)
      .shadow(radius: 20)
      .padding()
      .help("Add a column")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

fileprivate struct SubredditSelectorView: View {
  @State private var presentSelector: Bool = false
  @Binding var column: ColumnManager.Column
  @EnvironmentObject var informationBarData: InformationBarData
  let onExit: (UUID) -> Void

  init(column: Binding<ColumnManager.Column>, onExit: @escaping (UUID) -> Void) {
    self.onExit = onExit
    _column = column
  }

  @ViewBuilder var body: some View {
    VStack {
      HStack {
        Button(action: {
          onExit(column.id)
        }, label: {
          Image(systemName: "xmark.circle.fill")
        })
        Spacer()
        Text(column.selection == nil ? "Select" : column.selection!)
        Image(systemName: "chevron.down")
        Spacer()
      }
      .padding()
      .onTapGesture {
        presentSelector = true
      }
      .popover(isPresented: $presentSelector) {
        List(selection: $column.selection) {
          Section(header: Text("Meta")) {
            Label("Account", systemImage: "person.crop.circle")
              .help("Account view")
              .tag("__account__")
            Label("Search", systemImage: "magnifyingglass")
              .help("Search Reddit")
              .tag("__search__")
          }
          Divider()
          Section(header: Text("Front Page")) {
            ForEach(FrontPage.allCases) { page in
              Label(page.title, systemImage: page.systemImageIconName)
                .help(page.displayName)
                .tag(page)
            }
          }
          Divider()
          Section(header: Text("Multiredits")) {
            ForEach(informationBarData.multiReddits) { multireddit in
              HStack {
                SubredditIcon(multireddit: multireddit)
                  .frame(width: 24, height: 24)
                Text(multireddit.displayName)
              }
              .help(multireddit.displayName)
              .tag("m/\(multireddit.id)")
            }
          }
          Divider()
          Section(header: Text("Subscribed")) {
            ForEach(informationBarData.subscribedSubreddits) { subreddit in
              HStack {
                SubredditIcon(subreddit: subreddit)
                  .frame(width: 24, height: 24)
                Text(subreddit.displayName)
              }
              .help(subreddit.displayName)
              .tag(subreddit.name)
            }
          }
        }
      }

      Divider()
        .padding(.horizontal)
      
      if column.selection == "__account__" {
        accountView
      } else if column.selection == "__search__" {
        SearchView()
      } else if let page = selectedPage {
        PostListView(postContainer: page)
      } else if let multireddit = selectedMultireddit {
        PostListView(postContainer: multireddit)
      } else if let subreddit = selectedSubreddit {
        PostListView(postContainer: subreddit)
      } else {
        Spacer()
      }
    }
  }

  private var selectedSubreddit: Subreddit? {
    guard let selection = column.selection else { return nil }
    return informationBarData.subscribedSubreddits.first { $0.id == selection }
  }

  private var selectedMultireddit: Multireddit? {
    guard let selection = column.selection else { return nil }
    return informationBarData.multiReddits.first { $0.id == selection }
  }

  private var selectedPage: FrontPage? {
    guard let selection = column.selection else { return nil }
    return FrontPage.allCases.first { $0.id == selection }
  }

  @ViewBuilder private var accountView: some View {
    if let account = Illithid.shared.accountManager.currentAccount {
      AccountView(account: account)
    } else {
      Text("There is no logged in account")
    }
  }
}

final private class ColumnManager: ObservableObject {
  static let columnKey: String = "postGridView.columns"

  init() {
    guard let data = UserDefaults.standard.data(forKey: Self.columnKey),
          let saved = try? JSONDecoder().decode([Column].self, from: data) else {
      columns = [Column(selection: "__search__")]
      return
    }
    columns = saved
  }

  @Published var columns: [Column] {
    didSet {
      guard let data = try? JSONEncoder().encode(columns) else {
        return
      }

      UserDefaults.standard.set(data, forKey: Self.columnKey)
    }
  }

  func addColumn() {
    columns.append(Column())
  }

  func addColumn(selection: String) {
    columns.append(Column(selection: selection))
  }

  func removeColumn(id: UUID) {
    columns.removeAll { $0.id == id }
  }

  @discardableResult
  func removeLast() -> Column? {
    columns.popLast()
  }

  struct Column: Identifiable, Codable {
    let id: UUID
    var selection: String?

    init(id: UUID = UUID(), selection: String = "__search__") {
      self.id = id
      self.selection = selection
    }
  }
}
