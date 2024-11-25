//
//  SCPlacemark.swift
//  MapKit_iOS_UIKit
//
//  Created by sudhir on 24/11/24.
//

import MapKit.MKPlacemark
import Contacts.CNPostalAddress

class SCPlacemark: NSObject, Codable {
	
	var title: String?
	var subtitle: String?
	var coordinate: CLLocationCoordinate2D
	
	/// postal Address properties
	var street: String?
	var city: String?
	var state: String?
	
	/// address dictionary properties
	var name: String?
	var thoroughfare: String?
	var subThoroughfare: String?
	var locality: String?
	var subLocality: String?
	var administrativeArea: String?
	var subAdministrativeArea: String?
	var postalCode: String?
	var isoCountryCode: String?
	var country: String?
	var inlandWater: String?
	var ocean: String?
	var areasOfInterest: [String]?
	
	init(mkPlacemark: MKPlacemark) {
		name = mkPlacemark.name
		title = mkPlacemark.title
		if mkPlacemark.responds(to: #selector(getter: MKAnnotation.subtitle)) {
			subtitle = mkPlacemark.subtitle
		}
		coordinate = mkPlacemark.coordinate
		street = mkPlacemark.postalAddress?.street
		city = mkPlacemark.postalAddress?.city
		state = mkPlacemark.postalAddress?.state
		postalCode = mkPlacemark.postalAddress?.postalCode
		country = mkPlacemark.postalAddress?.country
		isoCountryCode = mkPlacemark.postalAddress?.isoCountryCode
		subAdministrativeArea = mkPlacemark.postalAddress?.subAdministrativeArea
		subLocality = mkPlacemark.postalAddress?.subLocality
	}
	
	/// Comparinng two objects are same or not
	override func isEqual(_ object: Any?) -> Bool {
		if let other = object as? SCPlacemark {
			return coordinate.latitude == other.coordinate.latitude && coordinate.longitude == other.coordinate.longitude
		} else {
			return false
		}
	}
}

// MARK: - Factory
extension SCPlacemark {
	/// Map to CNPostalAddress Model
	var toPostalAddress: CNPostalAddress {
		let postalAddress = CNMutablePostalAddress()
		postalAddress.street = street ?? ""
		postalAddress.city = city ?? ""
		postalAddress.state = state ?? ""
		postalAddress.postalCode = postalCode ?? ""
		postalAddress.country = country ?? ""
		postalAddress.isoCountryCode = isoCountryCode ?? ""
		postalAddress.subAdministrativeArea = subAdministrativeArea ?? ""
		postalAddress.subLocality = subLocality ?? ""
		return postalAddress.copy() as! CNPostalAddress
	}
	
	/// Map to MKPlacemark Model
	var toMKPlacemark: MKPlacemark {
		var addressDictionary: [String : Any] = [:]
		addressDictionary["name"] = name
		addressDictionary["thoroughfare"] = thoroughfare
		addressDictionary["locality"] = locality
		addressDictionary["subLocality"] = subLocality
		addressDictionary["administrativeArea"] = administrativeArea
		addressDictionary["subAdministrativeArea"] = subAdministrativeArea
		addressDictionary["postalCode"] = postalCode
		addressDictionary["isoCountryCode"] = isoCountryCode
		addressDictionary["country"] = country
		addressDictionary["inlandWater"] = inlandWater
		addressDictionary["ocean"] = ocean
		addressDictionary["areasOfInterest"] = areasOfInterest
		return MKPlacemark(coordinate: coordinate, addressDictionary: addressDictionary)
	}
	
	/// Map to MKMapItem model
	var toMapItem: MKMapItem {
		let item = MKMapItem(placemark: toMKPlacemark)
		item.name = name
		return item
	}
}

// MARK: - Debug Description
extension SCPlacemark {
	override var description: String {
		return """
		
		name: \(String(describing: name))
		title: \(String(describing: title))
		subtitle: \(String(describing: subtitle))
		latitude: \(coordinate.latitude)
		longitude: \(coordinate.longitude)
		
		"""
	}
}