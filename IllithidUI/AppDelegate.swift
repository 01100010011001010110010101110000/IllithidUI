//
// AppDelegate.swift
// Copyright (c) 2020 Flayware
// Created by Tyler Gregory (@01100010011001010110010101110000) on 8/1/20
//

import Cocoa
import Combine
import SwiftUI

import Alamofire
import Illithid
import OAuthSwift
import SDWebImage
import Ulithari
import Willow

@main
struct IllithidApp: App {
  private let illithid: Illithid = .shared

  @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

  var body: some Scene {
    WindowGroup {
      RootView()
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
      SidebarCommands()
      ToolbarCommands()
    }

    #if os(macOS)
      Settings {
        PreferencesView(accountManager: illithid.accountManager)
      }
    #endif
  }
}

class AppDelegate: NSObject, NSApplicationDelegate {
  let windowManager: WindowManager = .shared
  let illithid: Illithid = .shared
  let logger: Logger
  let session: Session

  override init() {
    #if DEBUG
      let logger: Logger = .debugLogger()
    #else
      let logger: Logger = .releaseLogger(subsystem: "com.flayware.IllithidUI")
    #endif
    self.logger = logger
    session = {
      let alamoConfiguration = URLSessionConfiguration.default

      // TODO: Make this some function of the system's available disk and memory
      alamoConfiguration.urlCache = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 200 * 1024 * 1024)

      let cacher: ResponseCacher = .cache
      let session = Session(configuration: alamoConfiguration,
                            rootQueue: DispatchQueue(label: "com.flayware.IllithidUI.AFRootQueue"),
                            serializationQueue: DispatchQueue(label: "com.flayware.IllithidUI.AFSerializationQueue"),
                            cachedResponseHandler: cacher,
                            eventMonitors: [FireLogger(logger: logger)])
      return session
    }()

    // MARK: SDWebImage configuration

    let cache = SDImageCache()
    cache.config.diskCacheExpireType = .modificationDate
    cache.config.maxDiskSize = 1024 * 1024 * 1024 * 2
    cache.config.maxMemoryCost = 1024 * 1024 * 200
    SDImageCachesManager.shared.caches = [cache]
    SDWebImageManager.defaultImageCache = SDImageCachesManager.shared

    super.init()
  }

  func applicationDidFinishLaunching(_: Notification) {
    illithid.configure(configuration: IllithidConfiguration())
    Ulithari.shared.configure(imgurClientId: "6f8b2f993cdf1f4")
    illithid.logger = logger
  }

  @objc private func newRootWindow() {
    windowManager.newRootWindow()
  }

  private func showMainWindow() {
    let controller = windowManager.showMainWindowTab(withId: "mainWindow") {
      RootView()
    }
    controller.window?.setFrameAutosaveName("Main Window")
  }

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

  // MARK: - Core Data Saving and Undo support

  @IBAction func saveAction(_: AnyObject?) {
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
}
