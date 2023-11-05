//
//  ContentView.swift
//  FenderFinderApp
//
//  Created by Adarsh Goura on 11/4/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject var locationService = LocationService()
    @StateObject var crashReportService = CrashReportService()
    @State var crashDetected = false

    var body: some View {
        VStack {
            Text("FenderFinder")
                .font(.largeTitle)
                .bold()
            Text("Live Crash Detection")
                .font(.title2)
                .foregroundColor(.gray)
            LiveFeedView(/*crashDetected: $crashDetected*/)
            CrashStatusView(crashDetected: $crashDetected)
        }
        .onAppear {
            locationService.startUpdatingLocation()
        }
    }
}


#Preview {
    ContentView()
}
