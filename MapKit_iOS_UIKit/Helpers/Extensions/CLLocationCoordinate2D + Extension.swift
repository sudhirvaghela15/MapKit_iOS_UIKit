//
//  CLLocationCoordinate2D.swift
//  MapKit_iOS_UIKit
//
//  Created by sudhir on 25/11/24.
//

import MapKit.MKPlacemark

// MARK: - CLLocationCoordinate2D
extension CLLocationCoordinate2D: Codable {
	enum CodingKeys: String, CodingKey {
		case latitude, longitude
	}
	
	public init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		let latitude = try values.decode(Double.self, forKey: .latitude)
		let longitude = try values.decode(Double.self, forKey: .longitude)
		self.init(latitude: latitude, longitude: longitude)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(latitude, forKey: .latitude)
		try container.encode(longitude, forKey: .longitude)
	}
}
