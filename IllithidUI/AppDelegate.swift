//
//  AppDelegate.swift
//  IllithidUI
//
//  Created by Tyler Gregory on 6/5/19.
//  Copyright © 2019 Tyler Gregory. All rights reserved.
//

import Cocoa
import SwiftUI

import Alamofire
import AlamofireImage
import Illithid
import OAuthSwift
import Willow

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
  var window: NSWindow!
  let illithid: Illithid = .shared

  #if DEBUG
    let logger: Logger = .debugLogger()
  #else
    let logger: Logger = .releaseLogger(subsystem: "com.illithid.illithid")
  #endif

  let imageDownloader = ImageDownloader(maximumActiveDownloads: 20)

  var preferencesWindowController: WindowController<PreferencesView>!

  func applicationDidFinishLaunching(_: Notification) {
    illithid.configure(configuration: IllithidConfiguration())
    illithid.logger = logger

    // MARK: Preferences Window Controller

    preferencesWindowController = WindowController(rootView: PreferencesView(accountManager: illithid.accountManager),
                                                   styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
                                                   title: "Illithid Preferences")
    preferencesWindowController.window!.center()

    let menu = NSApp.mainMenu!
    let preferencesItem = menu.item(withTitle: "Illithid")!.submenu!.item(withTitle: "Preferences…")!
    preferencesItem.action = #selector(NSWindow.makeKeyAndOrderFront(_:))
    preferencesItem.target = preferencesWindowController.window!

    // MARK: Application Root Window

    window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
      styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
      backing: .buffered, defer: false
    )
    window.center()
    window.setFrameAutosaveName("Main Window")

    let rootView = RootView().environmentObject(imageDownloader)

    window.contentView = NSHostingView(
      rootView: rootView
    )
    window.makeKeyAndOrderFront(nil)
  }

  func application(_: NSApplication, open urls: [URL]) {
    urls.forEach { url in
      if url.scheme == "illithid", url.host == "oauth2", url.path == "/callback" {
        OAuth2Swift.handle(url: url)
      }
    }
  }

  func applicationWillResignActive(_: Notification) {}

  func applicationWillTerminate(_: Notification) {}

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
