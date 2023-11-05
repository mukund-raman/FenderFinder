//
//  CrashReport.swift
//  FenderFinderApp
//
//  Created by Mukund Raman on 11/5/23.
//

import Foundation

struct CrashReport: Codable, Identifiable {
    var id: String
    let latitude: Double
    let longitude: Double
    let timestamp: Date
}
