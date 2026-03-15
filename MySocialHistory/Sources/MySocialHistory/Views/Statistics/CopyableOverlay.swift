import SwiftUI
import AppKit

// MARK: - Copyable Overlay Modifier

/// Adds a copy-to-clipboard button that appears on hover in the top-right corner.
/// Captures the window region corresponding to this view via CGWindowListCreateImage.
struct CopyableOverlay: ViewModifier {
    @State private var isHovering = false
    @State private var showCopied = false
    @State private var anchorView: NSView?
    @State private var viewSize: CGSize = .zero

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    ViewAnchor(nsView: $anchorView)
                        .preference(key: ViewSizeKey.self, value: geo.size)
                }
            )
            .onPreferenceChange(ViewSizeKey.self) { viewSize = $0 }
            .overlay(alignment: .topTrailing) {
                if isHovering {
                    Button(action: copyToClipboard) {
                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(showCopied ? .green : .secondary)
                            .frame(width: 26, height: 26)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .help("Copy to clipboard")
                    .padding(8)
                    .transition(.opacity)
                }
            }
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovering = hovering
                }
            }
    }

    @MainActor
    private func copyToClipboard() {
        guard let anchor = anchorView,
              let window = anchor.window else { return }

        // Hide the button before capturing
        isHovering = false

        // Wait one frame for the UI to redraw, then capture
        DispatchQueue.main.async {
            let target = Self.findTarget(from: anchor, targetSize: viewSize)
            let rectInWindow = target.convert(target.bounds, to: nil)
            let screenRect = window.convertToScreen(rectInWindow)

            guard let mainScreen = NSScreen.screens.first(where: { $0.frame.origin == .zero })
                                 ?? NSScreen.main else { return }
            let mainH = mainScreen.frame.height

            let captureRect = CGRect(
                x: screenRect.origin.x,
                y: mainH - screenRect.maxY,
                width: screenRect.width,
                height: screenRect.height
            )

            guard let cgImage = CGWindowListCreateImage(
                captureRect,
                .optionIncludingWindow,
                CGWindowID(window.windowNumber),
                [.boundsIgnoreFraming, .bestResolution]
            ) else { return }

            let image = Self.addWatermark(
                to: NSImage(cgImage: cgImage, size: screenRect.size)
            )

            NSPasteboard.general.clearContents()
            NSPasteboard.general.setData(image.tiffRepresentation!, forType: .tiff)

            withAnimation { showCopied = true }
            isHovering = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { showCopied = false }
            }
        }
    }

    // MARK: - Watermark

    private static func addWatermark(to source: NSImage) -> NSImage {
        let size = source.size
        let result = NSImage(size: size)
        result.lockFocus()

        // Draw the original image
        source.draw(in: NSRect(origin: .zero, size: size))

        // Load app icon
        let appIcon = NSApp.applicationIconImage ?? NSImage()
        let iconSize: CGFloat = 16
        let labelFont = NSFont.systemFont(ofSize: 11, weight: .medium)
        let labelText = "My Social History"
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: NSColor.secondaryLabelColor,
        ]
        let labelSize = (labelText as NSString).size(withAttributes: labelAttrs)

        let padding: CGFloat = 6
        let spacing: CGFloat = 4
        let badgeW = padding + iconSize + spacing + labelSize.width + padding
        let badgeH = max(iconSize, labelSize.height) + padding * 2

        // Position in top-right (NSImage origin is bottom-left)
        let badgeX = size.width - badgeW - 8
        let badgeY = size.height - badgeH - 8

        // Draw pill background
        let badgeRect = NSRect(x: badgeX, y: badgeY, width: badgeW, height: badgeH)
        let pill = NSBezierPath(roundedRect: badgeRect, xRadius: badgeH / 2, yRadius: badgeH / 2)
        NSColor(white: 1.0, alpha: 0.45).setFill()
        pill.fill()

        // Draw icon
        let iconY = badgeY + (badgeH - iconSize) / 2
        appIcon.draw(in: NSRect(x: badgeX + padding, y: iconY, width: iconSize, height: iconSize))

        // Draw label
        let labelY = badgeY + (badgeH - labelSize.height) / 2
        (labelText as NSString).draw(
            at: NSPoint(x: badgeX + padding + iconSize + spacing, y: labelY),
            withAttributes: labelAttrs
        )

        result.unlockFocus()
        return result
    }

    /// Walk up the superview chain and pick the view whose size best matches `targetSize`.
    private static func findTarget(from view: NSView, targetSize: CGSize) -> NSView {
        var best = view
        var bestDiff: CGFloat = .greatestFiniteMagnitude
        var current: NSView? = view

        while let v = current {
            let diff = abs(v.bounds.width - targetSize.width)
                     + abs(v.bounds.height - targetSize.height)
            if v.bounds.width >= 10, v.bounds.height >= 10, diff < bestDiff {
                bestDiff = diff
                best = v
            }
            // Stop if we've gone well past our target
            if v.bounds.width > targetSize.width + 200,
               v.bounds.height > targetSize.height + 200 {
                break
            }
            current = v.superview
        }
        return best
    }
}

// MARK: - NSView Anchor (captures a reference into the AppKit view hierarchy)

private struct ViewAnchor: NSViewRepresentable {
    @Binding var nsView: NSView?

    func makeNSView(context: Context) -> NSView {
        let v = NSView(frame: .zero)
        DispatchQueue.main.async { nsView = v }
        return v
    }

    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async { nsView = view }
    }
}

// MARK: - Preference Key

private struct ViewSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - View Extension

extension View {
    func copyable() -> some View {
        modifier(CopyableOverlay())
    }
}
