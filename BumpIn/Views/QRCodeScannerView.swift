import SwiftUI
import AVFoundation

struct QRCodeScannerView: View {
    @ObservedObject var cardService: BusinessCardService
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: QRCodeScannerViewModel
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    
    init(cardService: BusinessCardService) {
        self.cardService = cardService
        _viewModel = StateObject(wrappedValue: QRCodeScannerViewModel(cardService: cardService))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                QRCodeScannerViewRepresentable(viewModel: viewModel)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 250, height: 250)
                        .padding(.bottom, 40)
                    
                    // Add Photo Library Button
                    Button(action: {
                        showImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("Choose from Photos")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .padding(.bottom, 40)
                }
                
                if viewModel.showAlert {
                    Color.black.opacity(0.75)
                        .ignoresSafeArea()
                        .overlay(
                            VStack(spacing: 20) {
                                Text(viewModel.alertTitle)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(viewModel.alertMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                Button("OK") {
                                    viewModel.showAlert = false
                                    if viewModel.shouldDismiss {
                                        dismiss()
                                    }
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .cornerRadius(10)
                            }
                            .padding()
                        )
                }
            }
            .navigationTitle("Scan QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.startScanning()
        }
        .onDisappear {
            viewModel.stopScanning()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
        }
        .onChange(of: selectedImage) { newImage in
            if let image = newImage {
                viewModel.processQRCodeFromImage(image)
            }
        }
    }
}

class QRCodeScannerViewModel: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var shouldDismiss = false
    
    var captureSession: AVCaptureSession?
    private let metadataOutput = AVCaptureMetadataOutput()
    private let cardService: BusinessCardService
    
    init(cardService: BusinessCardService) {
        self.cardService = cardService
        super.init()
    }
    
    func startScanning() {
        guard captureSession == nil else { return }
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            displayAlert(title: "Error", message: "Camera is not available")
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            displayAlert(title: "Error", message: "Could not access camera")
            return
        }
        
        let captureSession = AVCaptureSession()
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            displayAlert(title: "Error", message: "Could not add camera input")
            return
        }
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            displayAlert(title: "Error", message: "Could not add QR code scanning")
            return
        }
        
        self.captureSession = captureSession
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
    }
    
    func stopScanning() {
        captureSession?.stopRunning()
        captureSession = nil
    }
    
    private func displayAlert(title: String, message: String, shouldDismiss: Bool = false) {
        self.alertTitle = title
        self.alertMessage = message
        self.shouldDismiss = shouldDismiss
        self.showAlert = true
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else {
            return
        }
        
        captureSession?.stopRunning()
        
        guard let data = stringValue.data(using: .utf8),
              let card = try? JSONDecoder().decode(BusinessCard.self, from: data) else {
            displayAlert(title: "Error", message: "Invalid QR code format")
            return
        }
        
        Task {
            do {
                try await cardService.addCard(card)
                await MainActor.run {
                    displayAlert(title: "Success", message: "Card added to your contacts!", shouldDismiss: true)
                }
            } catch {
                await MainActor.run {
                    displayAlert(title: "Error", message: "Failed to save card: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func processQRCodeFromImage(_ image: UIImage) {
        guard let ciImage = CIImage(image: image) else {
            displayAlert(title: "Error", message: "Could not process the selected image")
            return
        }
        
        let context = CIContext()
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        guard let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: options),
              let features = detector.features(in: ciImage) as? [CIQRCodeFeature],
              let qrCodeData = features.first?.messageString?.data(using: .utf8),
              let card = try? JSONDecoder().decode(BusinessCard.self, from: qrCodeData) else {
            displayAlert(title: "Error", message: "No valid QR code found in the image")
            return
        }
        
        Task {
            do {
                try await cardService.addCard(card)
                await MainActor.run {
                    displayAlert(title: "Success", message: "Card added to your contacts!", shouldDismiss: true)
                }
            } catch {
                await MainActor.run {
                    displayAlert(title: "Error", message: "Failed to save card: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct QRCodeScannerViewRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: QRCodeScannerViewModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        guard let captureSession = viewModel.captureSession else {
            return view
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
} 