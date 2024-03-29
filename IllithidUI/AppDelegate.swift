// Copyright (C) 2020 Tyler Gregory (@01100010011001010110010101110000)
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of  MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <http://www.gnu.org/licenses/>.

import Cocoa
import Combine
import SwiftUI

import Alamofire
import Illithid
import OAuthSwift
import SDWebImage
import Ulithari
import Willow

// MARK: - IllithidApp

@main
struct IllithidApp: App {
  // MARK: Lifecycle

  init() {
    illithid.configure(configuration: IllithidConfiguration())
    Ulithari.shared.configure(imgurClientId: "6f8b2f993cdf1f4")
    illithid.logger = delegate.logger
    OAuthSwift.log = delegate.logger

    // MARK: SDWebImage configuration

    let cache = SDImageCache()
    cache.config.diskCacheExpireType = .accessDate
    cache.config.maxDiskSize = 1024 * 1024 * 1024 * 2
    cache.config.maxMemoryCost = 1024 * 1024 * 200
    SDImageCachesManager.shared.caches = [cache]
    SDWebImageManager.defaultImageCache = SDImageCachesManager.shared
  }

  // MARK: Internal

  @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
  @Environment(\.scenePhase) var phase

  var body: some Scene {
    WindowGroup {
      RootView()
        .sheet(isPresented: $presentNewPostForm) {
          NewPostForm(isPresented: $presentNewPostForm)
        }
        .onChange(of: phase, perform: { phase in
          // TODO: Move pasteboard URL checking down here or also here
          switch phase {
          case .active:
            break
          case .inactive:
            break
          case .background:
            break
          @unknown default:
            fatalError("A new application phase has been added: \(phase)")
          }
        })
        .environment(\.illithidDatabase, .shared)
        .environmentObject(informationBarData)
        .onAppear {
          informationBarData.loadAccountData()
        }
        .onOpenURL { url in

          // MARK: OAuth2 Callback

          if url.scheme == "illithid", url.host == "oauth2", url.path == "/callback" {
            OAuth2Swift.handle(url: url)
          }

          // MARK: In App Link Handling

          else if url.scheme == "illithid", url.host == "open-url", url.query != nil {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            guard let linkString = components?.queryItems?
              .filter({ $0.name == "url" }).first?.value,
              let link = URL(string: linkString) else {
              delegate.logger.warnMessage("Unable to open URL: \(url.absoluteString)")
              return
            }

            if link.host == "reddit.com" ||
              link.host == "old.reddit.com" ||
              link.host == "www.reddit.com" {
              delegate.windowManager.openRedditLink(link: link)
            } else {
              delegate.windowManager.showMainWindowTab(withId: link.absoluteString) {
                WebView(url: link)
              }
            }
          }
        }
    }
    .commands {
      AboutCommands()
      SidebarCommands()
      ToolbarCommands()
      NewItemCommands(presentNewPostForm: $presentNewPostForm)
      #if DEBUG
      DebugCommands()
      #endif
    }

    #if os(macOS)
    Settings {
      PreferencesView(accountManager: illithid.accountManager)
    }
    #endif
  }

  // MARK: Private

  @State private var presentNewPostForm: Bool = false
  @StateObject private var informationBarData = InformationBarData()

  private let illithid: Illithid = .shared
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
  // MARK: Lifecycle

  override init() {
    #if DEBUG
    let logger: Logger = .debugLogger()
    #else
    let logger: Logger = .releaseLogger(subsystem: "com.flayware.IllithidUI")
    #endif
    self.logger = logger

    super.init()
  }

  // MARK: Internal

  let windowManager: WindowManager = .shared
  let logger: Logger

  // MARK: - Core Data stack

  lazy var persistentContainer: NSPersistentCloudKitContainer = {
    /*
     The persistent container for the application. This implementation
     creates and returns a container, having loaded the store for the
     application to it. This property is optional since there are legitimate
     error conditions that could cause the creation of the store to fail.
     */
    let container = NSPersistentCloudKitContainer(name: "IllithidUI")
    container.loadPersistentStores(completionHandler: { _, error in
      if let error = error {
        // Replace this implementation with code to handle the error appropriately.
        // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

        /*
         Typical reasons for an error here include:
         * The parent directory does not exist, cannot be created, or disallows writing.
         * The persistent store is not accessible, due to permissions or data protection when the device is locked.
         * The device is out of space.
         * The store could not be migrated to the current model version.
         Check the error message to determine what the actual problem was.
         */
        fatalError("Unresolved error \(error)")
      }
    })
    return container
  }()

  func applicationDidBecomeActive(_: Notification) {}

  func applicationDidFinishLaunching(_: Notification) {}

  func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
      showMainWindow()
    }
    return true
  }

  func applicationWillResignActive(_: Notification) {}

  func applicationWillTerminate(_: Notification) {}

  func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
    false
  }

  // MARK: - Core Data Saving and Undo support

  @IBAction
  func saveAction(_: AnyObject?) {
    // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
    let context = persistentContainer.viewContext

    if !context.commitEditing() {
      NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
    }
    if context.hasChanges {
      do {
        try context.save()
      } catch {
        // Customize this code block to include application-specific recovery steps.
        let nserror = error as NSError
        NSApplication.shared.presentError(nserror)
      }
    }
  }

  func windowWillReturnUndoManager(window _: NSWindow) -> UndoManager? {
    // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
    persistentContainer.viewContext.undoManager
  }

  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    // Save changes in the application's managed object context before the application terminates.
    let context = persistentContainer.viewContext

    if !context.commitEditing() {
      NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
      return .terminateCancel
    }

    if !context.hasChanges {
      return .terminateNow
    }

    do {
      try context.save()
    } catch {
      let nserror = error as NSError

      // Customize this code block to include application-specific recovery steps.
      let result = sender.presentError(nserror)
      if result {
        return .terminateCancel
      }

      let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
      let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info")
      let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
      let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
      let alert = NSAlert()
      alert.messageText = question
      alert.informativeText = info
      alert.addButton(withTitle: quitButton)
      alert.addButton(withTitle: cancelButton)

      let answer = alert.runModal()
      if answer == .alertSecondButtonReturn {
        return .terminateCancel
      }
    }
    // If we got here, it is time to quit.
    return .terminateNow
  }

  // MARK: Private

  @objc
  private func newRootWindow() {
    windowManager.newRootWindow()
  }

  private func showMainWindow() {
    let controller = windowManager.showMainWindowTab(withId: "mainWindow") {
      RootView()
    }
    controller.window?.setFrameAutosaveName("Main Window")
  }
}
