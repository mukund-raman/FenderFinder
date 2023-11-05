//
//  LiveFeedView.swift
//  FenderFinderApp
//
//  Created by Mukund Raman on 11/5/23.
//

import SwiftUI
import AVFoundation
import Combine
import TensorFlowLite

struct LiveFeedView: View {
    @StateObject private var viewModel = LiveFeedViewModel()
    
    var body: some View {
        ZStack {
            CameraView(cameraFramePublisher: viewModel.cameraFramePublisher)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("FenderFinder")
                    .font(.largeTitle)
                    .padding()
                
                Text("Live Crash Detection")
                    .font(.title2)
                    .padding(.bottom)
                
                Text(viewModel.crashDetected ? "Crash Detected!" : "No Crash Detected")
                    .bold()
                    .foregroundColor(viewModel.crashDetected ? .red : .gray)
            }
        }
        .onAppear {
            viewModel.startDetection()
        }
    }
}

class LiveFeedViewModel: ObservableObject {
    @Published var crashDetected: Bool = false
    let cameraFramePublisher = PassthroughSubject<CVPixelBuffer, Never>()
    
    private var cancellables: Set<AnyCancellable> = []
    private var interpreter: Interpreter
    
    init() {
//        let modelPath = Bundle.main.path(forResource: "default", ofType: "tflite", inDirectory: <#T##String?#>)!
        let modelPath = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent().path() + "default.tflite"
        print("modelPath: " + modelPath)
        interpreter = try! Interpreter(modelPath: modelPath)
        try? interpreter.allocateTensors()
    }
    
    func startDetection() {
        // Start the camera and begin sending frames to `cameraFramePublisher`
        
        // Subscribe to `cameraFramePublisher` to process frames and perform inference
        cameraFramePublisher
            .sink { [weak self] pixelBuffer in
                // Process the frame with the TensorFlow Lite model
                let isCrash = self?.performInference(on: pixelBuffer) ?? false
                DispatchQueue.main.async {
                    self?.crashDetected = isCrash
                    if isCrash {
                        // Send crash report to the database
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func performInference(on pixelBuffer: CVPixelBuffer) -> Bool {
        // Preprocess the frame to the format the TensorFlow Lite model expects
        // Perform inference with the TensorFlow Lite model
        // Interpret the results to determine if a crash is detected
        // This is a simplified placeholder logic
        do {
            try interpreter.copy(Data(), toInputAt: 0)
            try interpreter.invoke()
            let outputTensor = try interpreter.output(at: 0)
            // Interpret the output tensor data to detect a crash
            // Return true if a crash is detected, false otherwise
        } catch {
            print("Failed to perform inference: \(error)")
        }
        return false
    }
}

// `CameraView` would be a `UIViewControllerRepresentable` that sets up the camera feed
// and sends frames to `cameraFramePublisher`. It's not implemented here but would be similar
// to the `LiveFeedView` example provided earlier, with the addition of frame capture logic.

struct LiveFeedView_Previews: PreviewProvider {
    static var previews: some View {
        LiveFeedView()
    }
}
