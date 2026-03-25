import AppKit
import CoreGraphics
import Foundation

@MainActor
final class CursorOverlayWindowController {
    private let panel: NSPanel
    private let imageView = NSImageView()
    private var displayLinkTimer: Timer?
    private var theme: CursorTheme?
    private var matcher: CursorMatcher?
    private var currentRole: CursorRole = .arrow
    private var frameIndex = 0
    private var frameElapsed: TimeInterval = 0
    private var lastTick = Date()
    private var cursorHidden = false
    private var isRunning = false
    private var calibrations: [CursorRole: CursorCalibration] = [:]
    var onObservationChanged: ((CursorObservation) -> Void)?

    init() {
        panel = NSPanel(
            contentRect: .init(x: 0, y: 0, width: 64, height: 64),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.ignoresMouseEvents = true
        panel.hasShadow = false
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]

        imageView.imageScaling = .scaleNone
        imageView.frame = panel.contentView?.bounds ?? .zero
        imageView.autoresizingMask = [.width, .height]
        panel.contentView?.addSubview(imageView)
    }

    func setTheme(_ theme: CursorTheme, matcher: CursorMatcher) {
        self.theme = theme
        self.matcher = matcher
        syncToCurrentObservation(notify: true)
        updatePanelFrame(mouseLocation: NSEvent.mouseLocation)
    }

    func setCalibrations(_ calibrations: [CursorRole: CursorCalibration]) {
        self.calibrations = calibrations
        updatePanelFrame(mouseLocation: NSEvent.mouseLocation)
    }

    func start() {
        guard !isRunning else { return }
        guard theme != nil else { return }
        isRunning = true
        hideSystemCursorIfNeeded()
        panel.orderFrontRegardless()
        lastTick = Date()
        syncToCurrentObservation(notify: true)
        displayLinkTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        RunLoop.main.add(displayLinkTimer!, forMode: .common)
    }

    func stop() {
        isRunning = false
        displayLinkTimer?.invalidate()
        displayLinkTimer = nil
        panel.orderOut(nil)
        showSystemCursorIfNeeded()
    }

    private func tick() {
        guard let animation = currentAnimation else { return }
        let now = Date()
        let delta = now.timeIntervalSince(lastTick)
        lastTick = now

        updateRoleIfNeeded()

        frameElapsed += delta
        let currentDelay = animation.frames[frameIndex].delay
        if frameElapsed >= currentDelay {
            frameElapsed = 0
            frameIndex = (frameIndex + 1) % animation.frames.count
            updateImage()
        }
        updatePanelFrame(mouseLocation: NSEvent.mouseLocation)
    }

    private func updateImage() {
        guard let animation = currentAnimation else { return }
        let frame = animation.frames[frameIndex]
        imageView.image = frame.image
        panel.setContentSize(animation.canvasSize)
    }

    private func updatePanelFrame(mouseLocation: CGPoint) {
        guard let animation = currentAnimation else { return }
        let calibration = calibrations[currentRole] ?? .zero
        let origin = CGPoint(
            x: mouseLocation.x - animation.hotspot.x + calibration.offsetX,
            y: mouseLocation.y - (animation.canvasSize.height - animation.hotspot.y) + calibration.offsetY
        )
        panel.setFrame(.init(origin: origin, size: animation.canvasSize), display: false)
    }

    private var currentAnimation: CursorAnimation? {
        guard let theme else { return nil }
        return theme[currentRole] ?? theme[.arrow]
    }

    private func updateRoleIfNeeded() {
        guard let matcher else { return }
        let observation = matcher.currentObservation()
        guard observation.role != currentRole else { return }
        apply(observation)
        onObservationChanged?(observation)
    }

    private func syncToCurrentObservation(notify: Bool) {
        guard let matcher else { return }
        let observation = matcher.currentObservation()
        apply(observation)
        if notify {
            onObservationChanged?(observation)
        }
    }

    private func apply(_ observation: CursorObservation) {
        currentRole = observation.role
        frameIndex = 0
        frameElapsed = 0
        updateImage()
    }

    private func hideSystemCursorIfNeeded() {
        guard !cursorHidden else { return }
        let result = CGDisplayHideCursor(kCGNullDirectDisplay)
        if result == .success {
            cursorHidden = true
        }
    }

    private func showSystemCursorIfNeeded() {
        guard cursorHidden else { return }
        let result = CGDisplayShowCursor(kCGNullDirectDisplay)
        if result == .success {
            cursorHidden = false
        }
    }
}
