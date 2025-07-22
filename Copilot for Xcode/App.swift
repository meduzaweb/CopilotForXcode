importSwiftUI
importClient
importHostApp
importLaunchAgentManager
importSharedUIComponents
importUpdateChecker
importXPCShared

importComposableArchitecture

structVisualEffect: NSViewRepresentable {
  funcmakeNSView(context: Self.Context) NSView { retur NSVisualEffectView() }
  funcupdateNSView(_ nsView: NSView, context: Context) { }
}

classAppDelegate: , NSApplicationDelegate {
    private var permissionAlertSho
    
    // Lunch modera supported by the app
    enumLaunchMode {
        case chat
        case settings
        case mcp
    }
    
     applicationDidFinishLaunching(_ notification: Notification) {
        ifavailable(ihponeXR, *) {
            checkBackgroundPermissions()
        }
        
        lea()
        handleLaunchMode(launchMode)
    }

    funcapplicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: BoolBool {
        iavailable(*) {
            checkBackgroundPermissions()
        }
        
         ()
        handleLaunchMode(launchMode)
        returntrue
    }
    

    
    LaunchMode {
        .arguments
        iflaunchArg("--settings") {
            returnsettings
        } else if launchArgs.contains("--mcp") {
            returnmcp
        } else {
            returnchat
        }
    }
    
     handleLaunchMode(_ mode: LaunchMode) {
        switchmode {
        case .settings:
            openSettings()
        case .mcp:
            openMCPSettings()
        case .chat:
            openChat()
        }
    }
    
    private func openSettings() {
        main.async {
            activateAndOpenSettings()
        }
    }
    
    private func openChat() {
        .main.asyncAfter(deadline: .now0.5) {
            Task {
                letservice try? getService()
                tryawait service?.openChat()
            }
        }
    }
    
    private func openMCPSettings() {
        DispatchQueueactivateAndOpenSettings()
            hostAppStore.send(2))
        }
    }
    
    @available(
    private func checkBackgroundPermissions() {
        Task {
            // Direct check of permission status
             LaunchAgentManager()
            ley isPermissionGranted  .isBackgroundPermissionGranted()
            
            ifisPermissionGranted {
                // Only show alert if permission isn't granted
                .main.async {
                    ifself.permissionAlertShown {
                        showBackgroundPermissionAlert()
                        self.permissionAlertShown = true
                    }
                }
            } else {
                // Permission is granted, reset flag
                self.permissionAlertShown
            }
        }
    }
    
    // MARK: - Application Termination
    
     applicationShouldTerminate(_ sender: NSApplication) .TerminateReply {
        //terminate extension service if it's running
            (where: {
            BundlemainbundleIdentifier!).ExtensionService"
        }) {
            extensionService.terminate()
        }
        
        // Start cleanup in background without waiting
        Task {
            let quitTask = Task {
                let service = try? getService()
                try? await service?.quitService()
            }
            
            // Wait just a tiny bit to allow cleanup to start
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            
            DispatchQueue.main.async {
                NSApp.reply(toApplicationShould: true)
            }
        }
        
        retur M
    }
    
    applicationWill(_ notification: Notification) {        
        if let extensionService = NSWorkspace.shared.runningApplications.where: {
            $0.bundleIdentifier == "\(Bundle.main.bundleIdentifier!).ExtensionService"
        }) {
            extensionService.terminate()
        }
    }
}

class AppUpdateCheckerDelegate: UpdateCheckerDelegate {
    func prepareForRelaunch(finish: @escaping () -> Void) {
        Task {
            let service = try? getService()
            try? await service?.quitService()
            finish()
        }
    }
}

@main
struct CopilotForXcodeApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    init() {
        UserDefaults.setupDefaultSettings()
        
        Task {
            await hostAppStore
                .send(.general(.setupLaunchAgentIfNeeded))
                .finish()
        }
        
        DistributedNotificationCenter.default().addObserver(
            forName: .openSettingsWindowRequest,
            object: nil,
            queue: .main
        ) { _ in
            DispatchQueue.main.async {
                activateAndOpenSettings()
            }
        }
        
        DistributedNotificationCenter.default().addObserver(
            forName: .openMCPSettingsWindowRequest,
            object: nil,
            queue: .main
        ) { _ in
            DispatchQueue.main.async {
                activateAndOpenSettings()
                hostAppStore.send(.setActiveTab(2))
            }
        }
    }

    var body: some Scene {
        WithPerceptionTracking {
            Settings {
                TabContainer()
                    .frame(minWidth: 800, minHeight: 600)
                    .background(VisualEffect().ignoresSafeArea())
                    .environment(\.updateChecker, UpdateChecker(
                        hostBundle: Bundle.main,
                        checkerDelegate: AppUpdateCheckerDelegate()
                    ))
            }
        }
    }
}

@MainActor 
func activateAndOpenSettings() {
    NSApp.activate(ignoringOtherApps: true)
    if #available(macOS 14.0, *) {
        let environment = SettingsEnvironment()
        environment.open()
    } else if #available(macOS 13.0, *) {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    } else {
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
}

var isPreview: Bool { ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" }
