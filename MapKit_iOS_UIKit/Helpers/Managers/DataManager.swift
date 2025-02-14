//
//  DataManager.swift
//  MapKit_iOS_UIKit
//
//  Created by sudhir on 27/11/24.
//

import Foundation
import MapKit

class DataManager {
	typealias DirectionFetcher = (
		SCPlacemark,
		SCPlacemark,
		@escaping (_ result: Result<[MKRoute], Error>) -> ()
	) -> Void
	
	static let shared = DataManager()
	
	private let directionFetcher: DirectionFetcher
	
	init(directionFetcher: @escaping DirectionFetcher = MapMananger.calculateDirections) {
		self.directionFetcher = directionFetcher
	}
}

// MARK: - Direction
extension DataManager {
	
	func save(direction: DirectionModel) {
		do {
			let data = try JSONEncoder().encode(direction)
			let key = createKeyBy(source: direction.source, destination: direction.destination)
			UserDefaults.standard.set(data, forKey: key)
		} catch {
			print("Cant save direction with \(error)")
		}
	}

	func save(directions: [DirectionModel]) {
		for directionModel in directions {
			save(direction: directionModel)
		}
	}
	
	func findDirection(source: SCPlacemark, destination: SCPlacemark) -> DirectionModel? {
		let key = createKeyBy(source: source, destination: destination)
		guard let data = UserDefaults.standard.object(forKey: key) as? Data,
			let direction = try? JSONDecoder().decode(DirectionModel.self, from: data) else { return nil }
		return direction
	}
}

// MARK: - SCPlacemark
extension DataManager {

	private func createKeyBy(source: SCPlacemark, destination: SCPlacemark) -> String {
		return "\(source.coordinate.latitude),\(source.coordinate.longitude) - \(destination.coordinate.latitude),\(destination.coordinate.longitude)"
	}
	
	func fetchDirections(
		ofNew placemark: SCPlacemark,
		toOld placemarks: [SCPlacemark],
		current userPlacemark: SCPlacemark?,
		completeBlock: @escaping (Result<[DirectionModel], Error>)->()) {
		
			
		let  syncQueue = DispatchQueue(label: "Queue is Sync mutation")
		
		var error: Error?
		
		var directionsModels = [DirectionModel]()
		
		var jorneys = [(source: SCPlacemark, destination: SCPlacemark)]()
		
		if let userPlacemark = userPlacemark {
			jorneys.append((userPlacemark, placemark))
		}
		
		for oldPlacemark in placemarks {
			jorneys.append((oldPlacemark, placemark))
			jorneys.append((placemark, oldPlacemark))
		}
		
		let group = DispatchGroup()
		 
		for (source, destination) in jorneys {
			group.enter()
			self.directionFetcher(source, destination, { (state) in
				switch state {
					case .failure(let _error):
						syncQueue.sync {
							error = _error
						}
					case .success(let routes):
						let directions = DirectionModel(source: source, destination: destination, routes: routes)
						syncQueue.sync {
							directionsModels.append(directions)
						}
				}
				group.leave()
			})
			
//			group.wait() /// if we put wait over here then it will work serially
		}
//			group.wait()   /// if we put wait over here then it will work concurrently
			
		/// using notify becasue wait function will block main thread and that will create dead lock i
		group.notify(queue: .main) {
			if let error = error {
				completeBlock(.failure(error))
			} else {
				completeBlock(.success(directionsModels))
			}
		}
			
	}
}

// MARK: - Favorite placemark
extension DataManager {
	
	func addToFavorites(placemark: SCPlacemark) throws {
		do {
			try addToFavorites(placemarks: [placemark])
		} catch {
			throw error
		}
	}
	
	func addToFavorites(placemarks: [SCPlacemark]) throws {
		var favorites = favoritePlacemarks()
		placemarks.forEach { (placemark) in
			favorites.insert(placemark)
		}
		do {
			let data = try JSONEncoder().encode(favorites)
			let key = UserDefaults.Keys.FavoritePlacemarks
			UserDefaults.standard.set(data, forKey: key)
		} catch {
			throw error
		}
	}
	
	func favoritePlacemarks() -> Set<SCPlacemark> {
		let key = UserDefaults.Keys.FavoritePlacemarks
		guard
			let data = UserDefaults.standard.object(forKey: key) as? Data,
			let placemarks = try? JSONDecoder().decode(Set<SCPlacemark>.self, from: data)
			else {
				return Set<SCPlacemark>()
		}
		return placemarks
	}
}
