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
        // Here you can update the view controller when your SwiftUI state changes
    }
}

class CameraViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var cameraFramePublisher: PassthroughSubject<CVPixelBuffer, Never>?
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
    }

    private func setupCaptureSession() {
        captureSession.beginConfiguration()
        
        // Set the session preset as you wish
        captureSession.sessionPreset = .high

        // Set up the video input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoDeviceInput) else {
            return
        }
        captureSession.addInput(videoDeviceInput)

        // Set up the video output
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        guard captureSession.canAddOutput(videoOutput) else { return }
        captureSession.addOutput(videoOutput)

        captureSession.commitConfiguration()

        // Start the session
        captureSession.startRunning()
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        // Publish the frame to be processed by the SwiftUI view
        cameraFramePublisher?.send(pixelBuffer)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }
}
