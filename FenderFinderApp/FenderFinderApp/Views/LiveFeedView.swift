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
    private var labels: [String] = []
    
//    init() {
//        guard let modelPath = Bundle.main.path(forResource: "default", ofType: "tflite") else {
//            fatalError("Failed to find the model file.")
//        }
//        do {
//            interpreter = try Interpreter(modelPath: modelPath)
//            try interpreter.allocateTensors()
//        } catch {
//            fatalError("Failed to create the interpreter with error: \(error.localizedDescription)")
//        }
//    }
    
    init() {
        guard let modelPath = Bundle.main.path(forResource: "default", ofType: "tflite"),
              let labelsPath = Bundle.main.path(forResource: "labels", ofType: "txt") else {
            fatalError("Failed to find the model file or labels.")
        }
        do {
            // Load the labels
            let labelsContent = try String(contentsOfFile: labelsPath)
            labels = labelsContent.components(separatedBy: .newlines)
            
            // Initialize the interpreter
            interpreter = try Interpreter(modelPath: modelPath)
            try interpreter.allocateTensors()
        } catch {
            fatalError("Failed to load the model or labels with error: \(error.localizedDescription)")
        }
    }
    
    func startDetection() {
        // Start the camera and begin sending frames to `cameraFramePublisher`
        
        // Subscribe to `cameraFramePublisher` to process frames and perform inference
        cameraFramePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pixelBuffer in
                // Process the frame with the TensorFlow Lite model
                let isCrash = self?.performInference(on: pixelBuffer) ?? false
                self?.crashDetected = isCrash
                if isCrash {
                    // Send crash report to the database
                }
            }
            .store(in: &cancellables)
    }
    
//    private func performInference(on pixelBuffer: CVPixelBuffer) -> Bool {
//        // Ensure that the pixel buffer is in the correct format (RGB, etc.)
//        guard let rgbData = preprocess(pixelBuffer: pixelBuffer, modelInputSize: CGSize(width: 168, height: 224)) else {
//            print("Failed to preprocess pixel buffer")
//            return false
//        }
//
//        // Perform inference with the TensorFlow Lite model
//        do {
//            // Copy the RGB data to the input tensor
//            try interpreter.copy(rgbData, toInputAt: 0)
//            
//            // Run inference by invoking the interpreter
//            try interpreter.invoke()
//            
//            // Get the output tensor data from the interpreter
//            let outputTensor = try interpreter.output(at: 0)
//            
//            // Interpret the output tensor data to detect a crash
//            // The logic here will depend on the output format of your model
//            // For example, if your model outputs a single float value as a probability:
//            let probabilities = outputTensor.data.toArray(type: Float.self)
//            let crashProbability = probabilities.first ?? 0
//            
//            // Determine if a crash is detected based on the model's probability
//            // This threshold can be adjusted based on your model's behavior
//            let crashThreshold: Float = 0.5
//            let isCrashDetected = crashProbability > crashThreshold
//            
//            if isCrashDetected {
//                print("CRASH DETECTED!!!")
//            }
//            
//            // Return true if a crash is detected, false otherwise
//            return isCrashDetected
//        } catch {
//            print("Failed to perform inference: \(error)")
//            return false
//        }
//    }
    
    private func performInference(on pixelBuffer: CVPixelBuffer) -> Bool {
        // Ensure that the pixel buffer is in the correct format (RGB, etc.)
        guard let rgbData = preprocess(pixelBuffer: pixelBuffer, modelInputSize: CGSize(width: 168, height: 224)) else {
            print("Failed to preprocess pixel buffer")
            return false
        }

        // Perform inference with the TensorFlow Lite model
        do {
            // Copy the RGB data to the input tensor
            try interpreter.copy(rgbData, toInputAt: 0)
            
            // Run inference by invoking the interpreter
            try interpreter.invoke()
            
            // Get the output tensor data from the interpreter
            let outputTensor = try interpreter.output(at: 0)
            
            // Interpret the output tensor data to detect a crash
            let outputData = outputTensor.data.toArray(type: Float.self)
            print(outputData)
            
            // Find the index of the highest confidence value
            guard let maxConfidenceIndex = outputData.indices.max(by: { outputData[$0] < outputData[$1] }) else {
                print("Failed to find the index with the highest confidence.")
                return false
            }
            
            // Get the label with the highest confidence
            let detectedLabel = labels[maxConfidenceIndex]
            
            // Determine if a crash is detected based on the label
            let isCrashDetected = detectedLabel.lowercased().contains("crash")
            
            if isCrashDetected {
                print("CRASH DETECTED!!! Label: \(detectedLabel)")
            }
            
            // Return true if a crash is detected, false otherwise
            return isCrashDetected
        } catch {
            print("Failed to perform inference: \(error)")
            return false
        }
    }

    private func preprocess(pixelBuffer: CVPixelBuffer, modelInputSize: CGSize) -> Data? {
        // Lock the base address of the pixel buffer
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        // Get the number of bytes per row for the pixel buffer
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        // Create a CGImage from the pixel buffer
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: baseAddress, width: width, height: height,
                                      bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace,
                                      bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue),
              let cgImage = context.makeImage() else {
            return nil
        }
        
        // Create a new UIImage from the CGImage
        let image = UIImage(cgImage: cgImage)
        
        // Resize the image to the input size of the model
        guard let resizedImage = image.resized(to: modelInputSize) else {
            return nil
        }
        
        // Convert the UIImage to Data
        return resizedImage.pixelData()
    }
}

struct LiveFeedView_Previews: PreviewProvider {
    static var previews: some View {
        LiveFeedView()
    }
}
