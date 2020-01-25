//
//  AppDelegate.swift
//  Caffeinate
//
//  Created by zzada on 1/21/20.
//  Copyright © 2020 zzada. All rights reserved.
//

// https://www.flaticon.com/free-icon/coffee_996289

import OSLog
import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var process: Process? = nil
    var options = [String: NSControl.StateValue]()
    
    @IBOutlet weak var statusMenu: NSMenu!
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        // Set the icon
        let icon = NSImage(named: "CoffeeIcon")
        icon?.isTemplate = true // inverts in dark mode
        statusItem.button?.image = icon
        statusItem.menu = statusMenu
        
        // Initialize options
        for item in statusMenu.items {
            let id = item.identifier?.rawValue
            if id != nil && id!.hasPrefix("-") {
                options[id!] = item.state
            }
        }
    }

    @IBAction func stop(_ sender: NSMenuItem) {
        
        // Stop the running process
        if process != nil {
            os_log("Terminating process", type: .debug)
            process!.terminate()
        }
        
        // Disable this menu item
        sender.isEnabled = false
    }
    
    @IBAction func caffeinate(_ sender: NSMenuItem) {
        
        // Stop the running process
        if process != nil {
            process!.terminate()
        }
        
        // Set process options
        var arguments: [String] = []
        for (key, value) in options {
            if value == NSControl.StateValue.on {
                arguments.append(key)
            }
        }
        
        // Set time, if required
        let time = Int(sender.identifier!.rawValue)
        if time != nil {
            arguments.append("-t " + String(time! * 60))
        }
                
        // Run the process
        let command = URL(fileURLWithPath: "/usr/bin/caffeinate")
        do {
            os_log("Starting Process", type: .debug)
            sender.state = NSControl.StateValue.on
            statusMenu.item(at: 0)?.isEnabled = true
            try process = Process.run(command, arguments: arguments) { (Process) in
                os_log("Process completed", type: .debug)
                
                sender.state = NSControl.StateValue.off
                self.statusMenu.item(at: 0)?.isEnabled = false
            }
        } catch {
            os_log("Failed to run process", type: .error)
            process = nil
        }
    }
    
    @IBAction func selectOption(_ sender: NSMenuItem) {
        
        // Toggle the item's state
        if sender.state == NSControl.StateValue.on {
            sender.state = NSControl.StateValue.off
        }
        else if sender.state == NSControl.StateValue.off {
            sender.state = NSControl.StateValue.on
        }
        
        // Update options
        options.updateValue(sender.state, forKey: sender.identifier!.rawValue)
    }
    
    // Quit any running process and application
    @IBAction func quitClicked(sender: NSMenuItem) {
        if process != nil {
            process!.terminate()
        }
        
        NSApplication.shared.terminate(self)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Nothing
    }

}
