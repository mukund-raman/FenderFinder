//
//  CrashStatusView.swift
//  FenderFinderApp
//
//  Created by Mukund Raman on 11/5/23.
//

import Foundation
import SwiftUI

struct CrashStatusView: View {
    @Binding var crashDetected: Bool

    var body: some View {
        Text(crashDetected ? "Crash Detected!" : "No Crash Detected.")
            .bold()
            .foregroundColor(crashDetected ? .red : .gray)
    }
}
