//
//  DataManager.swift
//  MapKit_iOS_UIKit
//
//  Created by sudhir on 27/11/24.
//

import Foundation

class DataManager {
	
	static let shared = DataManager()
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
	
	func fetchDirections(ofNew placemark: SCPlacemark, toOld placemarks: [SCPlacemark], current userPlacemark: SCPlacemark?, completeBlock: @escaping (Result<[DirectionModel], Error>)->()) {
		DispatchQueue.global().async {
			
			let queue = OperationQueue()
			queue.name = "Fetch diretcions of placemarks"
			
			var directionsModels = [DirectionModel]()
			let callbackFinishOperation = BlockOperation {
				DispatchQueue.main.async {
					completeBlock(.success(directionsModels))
				}
			}
			
			if let userPlacemark = userPlacemark {
				let blockOperation = BlockOperation(block: {
					let semaphore = DispatchSemaphore(value: 0)
					let source = userPlacemark
					let destination = placemark
					MapMananger.calculateDirections(from: userPlacemark, to: placemark, completion: { (status) in
						switch status {
						case .success(let response):
							let directions = DirectionModel(source: source, destination: destination, routes: response.routes)
							directionsModels.append(directions)
						case .failure(let error):
							completeBlock(.failure(error))
						}
						semaphore.signal()
					})
					semaphore.wait()
				})
				callbackFinishOperation.addDependency(blockOperation)
				queue.addOperation(blockOperation)
			}
				/// current -> newPlacemark
				/// old1 -> newPlacemark
				/// newPlacemark -> old1
				/// old2 -> newPlacemark
				/// newPlacemark -> old2
			for oldPlacemark in placemarks {
				for tuple in [(oldPlacemark, placemark), (placemark, oldPlacemark)] {
					let source = tuple.0
					let destination = tuple.1
					let blockOperation = BlockOperation(block: {
						let semaphore = DispatchSemaphore(value: 0)
						MapMananger.calculateDirections(from: source, to: destination, completion: { (state) in
							switch state {
							case .failure(let error):
								completeBlock(.failure(error))
							case .success(let response):
								let directions = DirectionModel(source: source, destination: destination, routes: response.routes)
								directionsModels.append(directions)
							}
							semaphore.signal()
						})
						semaphore.wait()
					})
					
					callbackFinishOperation.addDependency(blockOperation)
					queue.addOperation(blockOperation)
				}
			}
			queue.addOperation(callbackFinishOperation)
			queue.waitUntilAllOperationsAreFinished()
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
