//
//  TourModel.swift
//  MapKit_iOS_UIKit
//
//  Created by sudhir on 05/02/25.
//

import MapKit.MKPlacemark

struct TourModel: Codable {
	
	var directions: [DirectionModel] = []
}

extension TourModel {
	
	var destinations: [SCPlacemark] {
		return directions.map{ $0.destination }
	}
	
	var polylines: [MKPolyline] {
		return directions.map{ $0.polyline }
	}
}

extension TourModel {
	
	var distances: CLLocationDistance {
		return directions.map{ $0.distance }.reduce(0, +)
	}
	
	var sumOfExpectedTravelTime: TimeInterval {
		return directions.map{ $0.expectedTravelTime }.reduce(0, +)
	}
	
	
	var time: String {
		String(format: "Time" + ": %.2f " + "min", sumOfExpectedTravelTime / 60)
	}
	
	var distance: String {
		String(format: "Distance" + ": %.2f " + "KM", distances / 1000)
	}
	
	
	var routeInformation: String {
		let distance = String(format: "Distance" + ": %.2f " + "km", distances/1000)
		let time = String(format: "Time" + ": %.2f " + "min", sumOfExpectedTravelTime/60)
		
		return distance + ", " + time
	}
}

extension TourModel: Comparable {
	
	static func <(lhs: TourModel, rhs: TourModel) -> Bool {
		return lhs.distances < rhs.distances
	}

	static func ==(lhs: TourModel, rhs: TourModel) -> Bool {
		return lhs.distances == rhs.distances
	}
}

extension TourModel: Hashable {
	
	func hash(into hasher: inout Hasher) {
		polylines.forEach { (polyline) in
			let coordinate = polyline.coordinate
			hasher.combine("\(coordinate.latitude)" + "+" + "\(coordinate.longitude)")
		}
	}
}
