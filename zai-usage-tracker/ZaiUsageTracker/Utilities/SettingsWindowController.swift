import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()
    
    var viewModel: UsageViewModel?
    private var hostingController: NSHostingController<AnyView>?
    
    private let windowSize = NSSize(width: 400, height: 500)
    
    private init() {
        // Create window with initial content rect
        let contentRect = NSRect(origin: .zero, size: windowSize)
        let window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.isReleasedWhenClosed = false
        window.center()
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        window.level = .floating
        window.minSize = NSSize(width: 400, height: 400)
        
        super.init(window: window)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show(viewModel: UsageViewModel) {
        self.viewModel = viewModel
        
        // Update root view each time to ensure fresh viewModel binding
        let container = SettingsContainerView(windowController: self)
        let containerView = AnyView(container.frame(width: windowSize.width, height: windowSize.height))
        
        if let existing = hostingController {
            existing.rootView = containerView
        } else {
            hostingController = NSHostingController(rootView: containerView)
            window?.contentViewController = hostingController
        }
        
        // Ensure window is correct size after content is set
        window?.setContentSize(windowSize)
        
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
    
    func closeWindow() {
        window?.performClose(nil)
    }
}

// MARK: - Container View

struct SettingsContainerView: View {
    weak var windowController: SettingsWindowController?
    
    var body: some View {
        if let vm = windowController?.viewModel {
            SettingsView(viewModel: vm, onClose: { [weak windowController] in
                windowController?.closeWindow()
            })
        } else {
            ProgressView("Loading...")
                .frame(width: 400, height: 500)
        }
    }
}
