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

let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

struct Command {
    var name: String
    var path: String
    var flags: [Flag] = []
    var options: [Option] = []
    
    struct Flag {
        var title: String
        var flag: String
        var help: String
    }
    
    struct Option {
        var title: String
        var flag: String
        var value: String
        var help: String
    }
    
    func getFlag(fromTitle: String) -> String? {
        for flag in flags {
            if flag.title == fromTitle {
                return flag.flag
            }
        }
        return nil
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {

    var command: Command!
    var process: Process!
    var statusBar: NSStatusBar!
    var statusItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {

        statusBar = NSStatusBar()
        statusItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(named: "CoffeeWhite")
            button.image?.isTemplate = true
            button.toolTip = "Caffeinate \(appVersion ?? "")"
        }
        
        command = Command(name: "caffeinate", path: "/usr/bin/caffeinate")
        command.flags.append(Command.Flag(title: "Disk", flag: "-m",
                                          help: "Create an assertion to prevent the disk from idle sleeping"))
        command.flags.append(Command.Flag(title: "Display", flag: "-d",
                                          help: "Create an assertion to prevent the display from sleeping"))
        command.flags.append(Command.Flag(title: "Idle sleep", flag: "-i",
                                          help: "Create an assertion to prevent the system from idle sleeping"))
        command.flags.append(Command.Flag(title: "System", flag: "-s",
                                          help: "Create an assertion to prevent the system from sleeping (AC power only)"))
        command.flags.append(Command.Flag(title: "Active user", flag: "-u",
                                          help: "Create an assertion to declare that user is active"))
        
        statusItem.menu = createMenu(command)
    }
    
    func createMenu(_ command: Command) -> NSMenu {
        let menu = NSMenu()
        
        // Time options
        let instruction = NSMenuItem(title: "Choose a duration", action: nil, keyEquivalent: "")
        instruction.isEnabled = false
        menu.addItem(instruction)
        
        let onImage = NSImage(named: NSImage.statusAvailableName)
        let option1 = NSMenuItem(title: "15 minutes", action: #selector(caffeinate), keyEquivalent: "")
        option1.onStateImage = onImage
        menu.addItem(option1)
        let option2 = NSMenuItem(title: "30 minutes", action: #selector(caffeinate), keyEquivalent: "")
        option2.onStateImage = onImage
        menu.addItem(option2)
        let option3 = NSMenuItem(title: "60 minutes", action: #selector(caffeinate), keyEquivalent: "")
        option3.onStateImage = onImage
        menu.addItem(option3)
        menu.addItem(withTitle: "Indefinitely", action: #selector(caffeinate), keyEquivalent: "")
        menu.addItem(.separator())
        
        // Flags
        let item = NSMenuItem(title: "Prevent from sleeping", action: nil, keyEquivalent: "")
        item.isEnabled = false
        menu.addItem(item)
        for flag in command.flags {
            let item = NSMenuItem(title: flag.title, action: #selector(toggleOption), keyEquivalent: "")
            item.state = .on
            item.toolTip = flag.help
            menu.addItem(item)
        }
        menu.addItem(.separator())
        
        menu.addItem(withTitle: "Quit", action: #selector(quitClicked), keyEquivalent: "")
        
        return menu
    }

    @objc func caffeinate(_ sender: NSMenuItem) {
        
        // Stop the running process
        if let runningProcess = process {
            runningProcess.terminate()
        }
        
        if sender.state == .on {
            sender.state = .off
            statusItem.button?.image = NSImage(named: "CoffeeWhite")
            statusItem.button?.image?.isTemplate = true
            return
        }
        
        // Set process options
        var arguments: [String] = []
        for item in statusItem.menu!.items {
            if item.state == .on {
                if let flag = command.getFlag(fromTitle: item.title) {
                    arguments.append(flag)
                }
            }
        }
        
        // Set time, if required
        if sender.title != "Indefinitely" {
            let time = Int(sender.title.prefix(2))
            arguments.append("-t " + String(time! * 60))
        }
                
        // Run the process
        let command = URL(fileURLWithPath: command.path)
        do {
            os_log("Starting Process", type: .debug)
            sender.state = .on
            statusItem.button?.image = NSImage(named: "CoffeeColor")
            statusItem.button?.image?.isTemplate = false
            try process = Process.run(command, arguments: arguments) { (Process) in
                os_log("Process completed", type: .debug)
                sender.state = .off
            }
        } catch {
            os_log("Failed to run process", type: .error)
            process = nil
            sender.state = .mixed
            sender.mixedStateImage = NSImage(named: NSImage.statusUnavailableName)
        }
    }
    
    @objc func toggleOption(_ sender: NSMenuItem) {
        sender.state = (sender.state == .on) ? .off : .on
    }
    
    // Quit any running process and application
    @objc func quitClicked(_ sender: NSMenuItem?) {
        if let runningProcess = process {
            runningProcess.terminate()
        }
        
        NSApplication.shared.terminate(self)
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        quitClicked(nil)
    }

}
