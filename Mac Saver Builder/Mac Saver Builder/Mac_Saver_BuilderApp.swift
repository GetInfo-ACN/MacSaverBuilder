//
//  Mac_Saver_BuilderApp.swift
//  Mac Saver Builder
//
//  Created by Hüseyin Usta
//  Copyright © 2024 GetInfo. Licensed under MIT License.
//

import SwiftUI

@main
struct Mac_Saver_BuilderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(width: 540, height: 254)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 540, height: 254)
        .defaultPosition(.center)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {

        if let emptyWindow = NSApplication.shared.windows.first(where: { $0.title.isEmpty }) {
            emptyWindow.close()
        }
        

        if NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier!).count > 1 {
            NSApplication.shared.terminate(nil)
        }
    }
}
