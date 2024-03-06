//
//  Caffeinate.swift
//  Caffeinate
//
//  Created by zzada on 1/27/24.
//  Copyright © 2024 zzada. All rights reserved.
//

import SwiftUI

@main
struct CaffeinateApp: App {
    @State private var isCaffeinated = false
    
    var body: some Scene {
        MenuBarExtra {
            AppMenu(isCaffeinated: $isCaffeinated)
        } label: {
            Image(systemName: "cup.and.saucer")
                .symbolVariant(.fill)
                .symbolRenderingMode(isCaffeinated ? .palette : nil)
                .foregroundStyle(.red)
        }
    }
}

struct AppMenu: View {
    @Binding var isCaffeinated: Bool
    
    @State private var diskSleepOn: Bool = true
    @State private var displaySleepOn: Bool = true
    @State private var idleSleepOn: Bool = true
    @State private var systemSleepOn: Bool = true
    @State private var activeSleepOn: Bool = true
        
    @State private var process: Process?
    
    var body: some View {
        Button(isCaffeinated ? "Cancel" : "Choose a duration",
               action: cancelProcess)
            .disabled(!isCaffeinated)
        Button("15 minutes") { runCommand(minutes: 15.0) }
            .disabled(isCaffeinated)
        Button("30 minutes") { runCommand(minutes: 30.0) }
            .disabled(isCaffeinated)
        Button("60 minutes") { runCommand(minutes: 60.0) }
            .disabled(isCaffeinated)
        Button("∞ indefinite") { runCommand(minutes: nil) }
            .disabled(isCaffeinated)
        Divider()
        Toggle("Disk", isOn: $diskSleepOn)
            .help("Create an assertion to prevent the disk from idle sleeping")
        Toggle("Display", isOn: $displaySleepOn)
            .help("Create an assertion to prevent the display from sleeping")
        Toggle("Idle Sleep", isOn: $idleSleepOn)
            .help("Create an assertion to prevent the system from idle sleeping")
        Toggle("System", isOn: $systemSleepOn)
            .help("Create an assertion to prevent the system from sleeping (AC power only)")
        Toggle("Active User", isOn: $activeSleepOn)
            .help("Create an assertion to declare that user is active")
        Divider()
        Button("Quit", role: .destructive) {
            cancelProcess()
            NSApplication.shared.terminate(nil)
        }
    }
    
    func cancelProcess() {
        if let process = process {
            process.interrupt()
        }
    }
    
    func runCommand(minutes: Double?) {
        let command = CaffeinateCommand(diskSleepOn: diskSleepOn,
                                        displaySleepOn: displaySleepOn,
                                        idleSleepOn: idleSleepOn,
                                        systemSleepOn: systemSleepOn,
                                        activeSleepOn: activeSleepOn,
                                        minutes: minutes)
        process = command.run() { _ in
            isCaffeinated = false
        }
        
        isCaffeinated = true
    }
}

struct CaffeinateCommand {
    private let path = "/usr/bin/caffeinate"
    
    var diskSleepOn: Bool
    var displaySleepOn: Bool
    var idleSleepOn: Bool
    var systemSleepOn: Bool
    var activeSleepOn: Bool
    var minutes: Double?
    
    private func getArguments() -> [String] {
        var arguments: [String] = []
        
        if diskSleepOn { arguments.append("-m") }
        if displaySleepOn { arguments.append("-d") }
        if idleSleepOn { arguments.append("-i") }
        if systemSleepOn { arguments.append("-s") }
        if activeSleepOn { arguments.append("-u") }
        
        if let minutes = minutes {
            arguments.append("-t " + String(minutes * 60))
        }
        
        return arguments
    }
    
    func run(terminationHandler: (@Sendable (Process) -> Void)? = nil) -> Process? {
        let arguments = getArguments()
        let command = URL(fileURLWithPath: path)
        do {
            let process = try Process.run(command,
                                          arguments: arguments,
                                          terminationHandler: terminationHandler)
            return process
        }
        catch {
            fatalError(error.localizedDescription)
        }
    }
}
