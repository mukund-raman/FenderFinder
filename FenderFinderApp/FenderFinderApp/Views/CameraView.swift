//
//  CameraView.swift
//  FenderFinderApp
//
//  Created by Mukund Raman on 11/5/23.
//

import SwiftUI
import AVFoundation
import Combine

struct CameraView: UIViewControllerRepresentable {
    var cameraFramePublisher: PassthroughSubject<CVPixelBuffer, Never>

    func makeUIViewController(context: Context) -> CameraViewController {
        let viewController = CameraViewController()
        viewController.cameraFramePublisher = cameraFramePublisher
        return viewController
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // This method intentionally left blank
    }
}

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var cameraFramePublisher: PassthroughSubject<CVPixelBuffer, Never>?
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        checkPermissionsAndSetupCaptureSession()
    }

    private func checkPermissionsAndSetupCaptureSession() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                setupCaptureSession()
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        DispatchQueue.main.async {
                            self.setupCaptureSession()
                        }
                    }
                }
            case .denied, .restricted:
                // Handle the error case where the user has previously denied access.
                return
            @unknown default:
                // Handle future cases
                return
        }
    }

    private func setupCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.beginConfiguration()
            
            // Set the session preset as you wish
            self.captureSession.sessionPreset = .high

            // Set up the video input
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
                  self.captureSession.canAddInput(videoDeviceInput) else {
                return
            }
            self.captureSession.addInput(videoDeviceInput)

            // Set up the video output
            self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            guard self.captureSession.canAddOutput(self.videoOutput) else { return }
            self.captureSession.addOutput(self.videoOutput)

            self.captureSession.commitConfiguration()
            
            DispatchQueue.main.async {
                self.addPreviewLayer()
            }

            // Start the session
            self.captureSession.startRunning()
        }
    }
    
    private func addPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        if let previewLayer = self.previewLayer {
            view.layer.insertSublayer(previewLayer, at: 0)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        // Publish the frame to be processed by the SwiftUI view
        DispatchQueue.main.async {
            self.cameraFramePublisher?.send(pixelBuffer)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }
}
