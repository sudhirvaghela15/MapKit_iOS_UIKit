//
//  MapManager.swift
//  MapKit_iOS_UIKit
//
//  Created by sudhir on 26/11/24.
//

import MapKit


class MapMananger { }

extension MapMananger {
	class func fetchLocalSearch(with keywords: String, region: MKCoordinateRegion,  completion: @escaping (_ result: Result<MKLocalSearch.Response, Error>) -> ()) {
		let request = MKLocalSearch.Request()
		request.naturalLanguageQuery = keywords
		request.region = region
		
		let search = MKLocalSearch(request: request)
		search.start { (response, error) in
			if let response = response {
				completion(.success(response))
			}
			
			if let error = error {
				completion(.failure(error))
			}
		}
	}
}
