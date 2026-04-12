import Foundation
import UserNotifications
import AppKit

protocol NotificationSending {
    func requestAuthorizationIfNeeded() async
    func send(title: String, body: String, id: String)
}

final class NotificationService: NotificationSending {
    private let center: UNUserNotificationCenter
    private var didRequestAuthorization = false
    private lazy var iconAttachment: UNNotificationAttachment? = makeIconAttachment()

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorizationIfNeeded() async {
        guard !didRequestAuthorization else {
            return
        }

        didRequestAuthorization = true

        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Notification authorization error:", error)
        }
    }

    func send(title: String, body: String, id: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        if let iconAttachment {
            content.attachments = [iconAttachment]
        }

        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)

        center.add(request) { error in
            if let error {
                print("Notification scheduling error:", error)
            }
        }
    }

    private func makeIconAttachment() -> UNNotificationAttachment? {
        let image = NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
        guard let tiffData = image.tiffRepresentation else {
            return nil
        }

        guard let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("cricinfo-notification-icon.png")

        do {
            try pngData.write(to: fileURL, options: [.atomic])
            return try UNNotificationAttachment(identifier: "app-icon", url: fileURL)
        } catch {
            print("Notification icon attachment error:", error)
            return nil
        }
    }
}
