//
//  CrashReportService.swift
//  FenderFinderApp
//
//  Created by Mukund Raman on 11/5/23.
//

import Foundation
import CoreLocation

class CrashReportService: ObservableObject {
    
    let baseURL = URL(string: "YOUR_SERVER_URL")!
    
    func sendCrashReport(latitude: Double, longitude: Double, userReport: String, completion: @escaping (Bool, Error?) -> Void) {
        let endpoint = baseURL.appendingPathComponent("/reportCrash")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "userReport": userReport
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                completion(false, error)
                return
            }
            completion(true, nil)
        }.resume()
    }
    
    func checkForNearbyCrashes(userLocation: CLLocation, completion: @escaping ([CLLocation]?) -> Void) {
        let endpoint = baseURL.appendingPathComponent("/crashes")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let data = data else {
                completion(nil)
                return
            }
            
            do {
                // Assuming the server returns an array of crash reports with latitude and longitude.
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    let nearbyCrashes = jsonArray.compactMap { dict -> CLLocation? in
                        guard let latitude = dict["latitude"] as? Double,
                              let longitude = dict["longitude"] as? Double else {
                            return nil
                        }
                        let crashLocation = CLLocation(latitude: latitude, longitude: longitude)
                        return crashLocation
                    }.filter { crashLocation in
                        return userLocation.distance(from: crashLocation) <= 8046.72 // 5 miles in meters
                    }
                    completion(nearbyCrashes)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }.resume()
    }
}
