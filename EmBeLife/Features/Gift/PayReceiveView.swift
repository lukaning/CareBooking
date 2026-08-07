import AVFoundation
import CoreImage.CIFilterBuiltins
import PhotosUI
import SwiftUI
import UIKit
import Vision

// MARK: - Entry model

enum PayReceiveTab: String, CaseIterable, Identifiable {
    case scanCode = "Scan code"
    case giftMe = "Gift me"

    var id: String { rawValue }
}

// MARK: - Pay / Receive root

struct PayReceiveView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var appModel

    @State private var selectedTab: PayReceiveTab = .scanCode
    @State private var giftAlert: String?
    @State private var copied = false
    @State private var showReceiverFlow = false
    @State private var giftPath: [GiftExperienceRoute] = []
    @State private var giftDraft = GiftDraft()

    private let segmentTrack = Color(red: 0.94, green: 0.945, blue: 0.96)
    private let linkPurple = Color(red: 0.45, green: 0.35, blue: 0.85)

    private var giftLink: String {
        let slug: String
        if !appModel.userEmail.isEmpty {
            let local = appModel.userEmail.split(separator: "@").first.map(String.init) ?? "user"
            slug = local.lowercased().replacingOccurrences(of: ".", with: "")
        } else if !appModel.profile.firstName.isEmpty {
            slug = appModel.profile.firstName.lowercased()
        } else {
            slug = "katie"
        }
        return "https://embelife.app/gift/\(slug)"
    }

    var body: some View {
        VStack(spacing: 0) {
            segmentControl
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)

            Group {
                switch selectedTab {
                case .scanCode:
                    ScanCodeTab(
                        expectedGiftLink: giftLink,
                        onGiftDetected: handleGiftScan
                    )
                case .giftMe:
                    GiftMeTab(
                        giftLink: giftLink,
                        linkPurple: linkPurple,
                        onCopied: {
                            UIPasteboard.general.string = giftLink
                            withAnimation { copied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                                withAnimation { copied = false }
                            }
                        },
                        copied: copied
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Pay / Receive")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showReceiverFlow) {
            NavigationStack(path: $giftPath) {
                GiftReceivedView(draft: giftDraft, path: $giftPath) {
                    showReceiverFlow = false
                    giftPath = []
                }
                .navigationDestination(for: GiftExperienceRoute.self) { route in
                    GiftExperienceDestination(route: route, draft: giftDraft, path: $giftPath)
                }
            }
        }
        .alert("Gift", isPresented: Binding(
            get: { giftAlert != nil },
            set: { if !$0 { giftAlert = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(giftAlert ?? "")
        }
    }

    private var segmentControl: some View {
        HStack(spacing: 0) {
            ForEach(PayReceiveTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.subheadline.weight(selectedTab == tab ? .semibold : .regular))
                        .foregroundStyle(selectedTab == tab ? Theme.darkText : Theme.mutedText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background {
                            if selectedTab == tab {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(segmentTrack)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func handleGiftScan(_ payload: String) {
        if isGiftPayload(payload) {
            giftDraft = GiftDraft()
            giftPath = []
            showReceiverFlow = true
        } else {
            giftAlert = "Scanned: \(payload)"
        }
    }

    private func isGiftPayload(_ value: String) -> Bool {
        let lower = value.lowercased()
        return lower.contains("embelife.app/gift")
            || lower.contains("gift/")
            || lower.hasPrefix("embelifegift:")
    }
}

// MARK: - Scan code

private struct ScanCodeTab: View {
    let expectedGiftLink: String
    var onGiftDetected: (String) -> Void

    @State private var showCamera = false
    @State private var photoItem: PhotosPickerItem?
    @State private var statusText = "Point your camera at a gift QR code"
    @State private var lastScanned: String?
    @State private var cameraError: String?

    private let accentPeach = Color(red: 1.0, green: 0.90, blue: 0.86)

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)

            qrDisplay
                .padding(.horizontal, 40)

            Text(statusText)
                .font(.subheadline)
                .foregroundStyle(Theme.mutedText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 20)

            if let lastScanned {
                Text(lastScanned)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Theme.brandOrange)
                    .lineLimit(2)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
            }

            Spacer(minLength: 16)

            bottomActions
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
        }
        .fullScreenCover(isPresented: $showCamera) {
            QRScannerScreen(
                onCode: { code in
                    showCamera = false
                    applyScan(code)
                },
                onCancel: { showCamera = false },
                onError: { message in
                    cameraError = message
                    showCamera = false
                }
            )
        }
        .alert("Camera", isPresented: Binding(
            get: { cameraError != nil },
            set: { if !$0 { cameraError = nil } }
        )) {
            Button("OK", role: .cancel) {}
            Button("Use sample gift QR") {
                applyScan(expectedGiftLink)
            }
        } message: {
            Text(cameraError ?? "")
        }
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                await decodePhoto(item)
            }
        }
    }

    private var qrDisplay: some View {
        ZStack {
            if let image = QRCodeGenerator.image(from: expectedGiftLink, dimension: 240) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .padding(20)
            }

            ScannerFrameCorners()
                .stroke(Theme.darkText, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: 260, height: 260)
        }
        .frame(width: 280, height: 280)
    }

    private var bottomActions: some View {
        HStack(spacing: 28) {
            PhotosPicker(selection: $photoItem, matching: .images) {
                Image(systemName: "photo.on.rectangle")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.darkText.opacity(0.75))
                    .frame(width: 52, height: 52)
                    .background(accentPeach)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Choose from gallery")

            Button {
                startCameraScan()
            } label: {
                Image(systemName: "viewfinder")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 72)
                    .background(Theme.brandOrange)
                    .clipShape(Circle())
                    .shadow(color: Theme.brandOrange.opacity(0.35), radius: 12, y: 4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Scan code")

            Button {
                // Import / folder — open document types as image via Photos for simplicity
                statusText = "Paste or open a gift QR from Photos, or tap Scan."
            } label: {
                Image(systemName: "folder")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.darkText.opacity(0.75))
                    .frame(width: 52, height: 52)
                    .background(accentPeach)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open folder")
        }
    }

    private func startCameraScan() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showCamera = true
                    } else {
                        cameraError = "Camera access is needed to scan gift QR codes."
                    }
                }
            }
        case .denied, .restricted:
            cameraError = "Camera access is denied. Enable it in Settings, or choose a QR image from your gallery."
        @unknown default:
            cameraError = "Unable to access the camera."
        }
    }

    private func applyScan(_ code: String) {
        lastScanned = code
        statusText = "Code scanned successfully"
        onGiftDetected(code)
    }

    @MainActor
    private func decodePhoto(_ item: PhotosPickerItem) async {
        statusText = "Reading image…"
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else {
                statusText = "Could not load that image."
                return
            }
            if let payload = QRCodeGenerator.detectPayload(in: uiImage) {
                applyScan(payload)
            } else {
                statusText = "No QR code found in the image."
            }
        } catch {
            statusText = "Could not read the selected photo."
        }
    }
}

// MARK: - Gift me

private struct GiftMeTab: View {
    let giftLink: String
    let linkPurple: Color
    var onCopied: () -> Void
    var copied: Bool

    private let muted = Color(red: 0.55, green: 0.58, blue: 0.65)

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 8)

            Image("giftMeIllustration")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 280)
                .frame(height: 170)
                .accessibilityHidden(true)

            Text("Your gift receiving Link")
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.darkText)
                .multilineTextAlignment(.center)

            Text("Receive gift fund or service by using the link below, or QR code, follow the guidance to finish the process")
                .font(.subheadline)
                .foregroundStyle(muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            if let qr = QRCodeGenerator.image(from: giftLink, dimension: 160) {
                Image(uiImage: qr)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .padding(10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(red: 0.90, green: 0.91, blue: 0.93), lineWidth: 1)
                    )
            }

            HStack(spacing: 12) {
                Text(truncatedLink)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.darkText)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(copied ? "Copied" : "Copy link") {
                    onCopied()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(linkPurple)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(red: 0.88, green: 0.89, blue: 0.91), lineWidth: 1)
            )
            .padding(.horizontal, 20)

            Spacer(minLength: 20)
        }
    }

    private var truncatedLink: String {
        if giftLink.count <= 28 { return giftLink }
        let prefix = giftLink.prefix(24)
        return "\(prefix)…"
    }
}

// MARK: - QR utilities

enum QRCodeGenerator {
    static func image(from string: String, dimension: CGFloat) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scale = dimension / output.extent.width
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    static func detectPayload(in image: UIImage) -> String? {
        guard let cgImage = image.cgImage else { return nil }
        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
        return (request.results ?? [])
            .compactMap { $0.payloadStringValue }
            .first
    }
}

// MARK: - Scanner frame corners

private struct ScannerFrameCorners: Shape {
    var cornerLength: CGFloat = 28

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let l = cornerLength
        // TL
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + l))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + l, y: rect.minY))
        // TR
        path.move(to: CGPoint(x: rect.maxX - l, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + l))
        // BR
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - l))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - l, y: rect.maxY))
        // BL
        path.move(to: CGPoint(x: rect.minX + l, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - l))
        return path
    }
}

// MARK: - Camera scanner

private struct QRScannerScreen: View {
    var onCode: (String) -> Void
    var onCancel: () -> Void
    var onError: (String) -> Void

    var body: some View {
        ZStack {
            QRCameraPreview(onCode: onCode, onError: onError)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button("Cancel", action: onCancel)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding()
                    Spacer()
                }
                Spacer()
                Text("Align a gift QR code inside the frame")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.bottom, 40)
            }

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.9), lineWidth: 2)
                .frame(width: 250, height: 250)
        }
        .background(Color.black)
    }
}

private struct QRCameraPreview: UIViewControllerRepresentable {
    var onCode: (String) -> Void
    var onError: (String) -> Void

    func makeUIViewController(context: Context) -> QRCameraViewController {
        let controller = QRCameraViewController()
        controller.onCode = onCode
        controller.onError = onError
        return controller
    }

    func updateUIViewController(_ uiViewController: QRCameraViewController, context: Context) {}
}

private final class QRCameraViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCode: ((String) -> Void)?
    var onError: ((String) -> Void)?

    private let session = AVCaptureSession()
    private var didEmit = false
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configureSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning {
            session.stopRunning()
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        guard
            let device = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            DispatchQueue.main.async {
                self.onError?("Camera is unavailable on this device. Try the gallery picker, or use the sample gift QR.")
            }
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            DispatchQueue.main.async {
                self.onError?("Unable to configure QR scanning.")
            }
            session.commitConfiguration()
            return
        }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = [.qr]
        session.commitConfiguration()

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.insertSublayer(layer, at: 0)
        previewLayer = layer
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !didEmit,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              object.type == .qr,
              let value = object.stringValue,
              !value.isEmpty
        else { return }

        didEmit = true
        session.stopRunning()
        onCode?(value)
    }
}

#Preview {
    NavigationStack {
        PayReceiveView()
    }
    .environment(AppModel())
}
