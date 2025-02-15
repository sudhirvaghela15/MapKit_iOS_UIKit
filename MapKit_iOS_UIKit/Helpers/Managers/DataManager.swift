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
	private typealias Journey = (source: SCPlacemark, destination: SCPlacemark)
	
	private func createKeyBy(source: SCPlacemark, destination: SCPlacemark) -> String {
		return "\(source.coordinate.latitude),\(source.coordinate.longitude) - \(destination.coordinate.latitude),\(destination.coordinate.longitude)"
	}
	
	func fetchDirections(
		ofNew placemark: SCPlacemark,
		toOld placemarks: [SCPlacemark],
		current userPlacemark: SCPlacemark?,
		completeBlock: @escaping (Result<[DirectionModel], Error>)->()) {
		
		var journeys = [Journey]()
		
		if let userPlacemark = userPlacemark {
			journeys.append((userPlacemark, placemark))
		}
		
		for oldPlacemark in placemarks {
			journeys.append((oldPlacemark, placemark))
			journeys.append((placemark, oldPlacemark))
		}
		/// concurrent way not good for fetching direction because of if first call got fail but other call are  still progress and  they are not cancelled hec
		/*
		let  syncQueue = DispatchQueue(label: "Queue is Sync mutation")
		
		var error: Error?
		
		var directionsModels = [DirectionModel]()
		
		let group = DispatchGroup()
		 
		for (source, destination) in journeys {
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
		 */
		directions(for: journeys, completion: { result in
			DispatchQueue.main.async {
				completeBlock(result)
			}
		})
	}
	
	/// this will working in Recursively once all journey operation will copmlete it will complete with success and notify to root caller with accumulated destinations array and if  any call got fail it will stop calling recursively and throw failure
	private func directions(
		for journeys: [Journey],
		accumulated: [DirectionModel] = [],
		completion:  @escaping (Result<[DirectionModel], Error>) -> Void) {
			guard let (source, destination) = journeys.first else {
				return completion(.success(accumulated))
			}
			
			self.directionFetcher(source, destination, { (result) in
				switch result {
					case .failure(let error):
						completion(.failure(error))
						
					case .success(let routes):
						let direction = DirectionModel(
							source: source,
							destination: destination,
							routes: routes
						)
						
						self.directions(
							for: Array(journeys.dropFirst()),
							accumulated: accumulated + [direction],
							completion: completion
						)
				}
			})
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
