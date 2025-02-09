//
//  HYCAnntation.swift
//  MapKit_iOS_UIKit
//
//  Created by sudhir on 06/02/25.
//


import MapKit.MKAnnotation

class SCAnnotation: NSObject {
	
	private let placemark: SCPlacemark
	let sorted: Int
	
	init(placemark: SCPlacemark, sorted: Int) {
		self.placemark = placemark
		self.sorted = sorted
	}
}

extension SCAnnotation: MKAnnotation {
	
	var coordinate: CLLocationCoordinate2D {
		return placemark.coordinate
	}

	var title: String? {
		return placemark.name
	}

    var subtitle: String? {
		return placemark.title
	}
}
