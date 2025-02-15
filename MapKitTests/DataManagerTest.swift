//
//  DataManagerTest.swift
//  MapKit_iOS_UIKitTests
//
//  Created by sudhir on 13/02/25.
//

import XCTest
import MapKit
@testable import MapKit_iOS_UIKit

final class DataManagerTest: XCTestCase {
	
	func test_fetchDirections_succeedsWhenAllRequestSucceed() {
		let newPlacemark = SCPlacemark(name: "new placemark")
	
		/// current -> newPlacemark
		let currentToNewPlacemarkDirection = DirectionModel(
			source: SCPlacemark(name: "current placemark"),
			destination: newPlacemark,
			routes: [MKRoute()]
		)
		
		/// old1 -> newPlacemark
		let oldToNewPlacemarkDirection1 = DirectionModel(
			source: SCPlacemark(name: "old placemark 1"),
			destination: newPlacemark ,
			routes: [MKRoute()]
		)
		
		/// newPlacemark -> old1
		let newToOldPlacemarkDirection1 = DirectionModel(
			source: oldToNewPlacemarkDirection1.destination,
			destination: oldToNewPlacemarkDirection1.source,
			routes: [MKRoute()]
		)
		
		/// old2 -> newPlacemark
		let oldToNewPlacemarkDirection2 = DirectionModel(
			source: SCPlacemark(name: "old placemark 2"),
			destination: newPlacemark,
			routes: [MKRoute()]
		)
		
		/// newPlacemark -> old2
		let newToOldPlacemarkDirection2 = DirectionModel(
			source: oldToNewPlacemarkDirection2.destination,
			destination: oldToNewPlacemarkDirection2 .source,
			routes: [MKRoute()]
		)
		 
		
		let sut = DataManager { source, destination, completion in
			completion(.success([MKRoute()]))
		}
		
		let exp = expectation(description: "Wait for fetch completion")
		
		sut.fetchDirections(
				ofNew: newPlacemark,
				toOld: [oldToNewPlacemarkDirection1.source,
						oldToNewPlacemarkDirection2.source],
				current: currentToNewPlacemarkDirection.source) { result in
					
					switch result {
						case .success(let directions):
							XCTAssertEqual(directions.count, 5)
							XCTAssertTrue(directions.contains(currentToNewPlacemarkDirection), "missing currentToNewPlacemarkDirection")
							XCTAssertTrue(directions.contains(oldToNewPlacemarkDirection1), "missing oldToNewPlacemarkDirection1")
							XCTAssertTrue(directions.contains(newToOldPlacemarkDirection1), "missing newToOldPlacemarkDirection1")
							XCTAssertTrue(directions.contains(oldToNewPlacemarkDirection2), "missing oldToNewPlacemarkDirection2")
							XCTAssertTrue(directions.contains(newToOldPlacemarkDirection2), "missing newToOldPlacemarkDirection2")
							/*
							XCTAssertEqual(directions, [
								currentToNewPlacemarkDirection,
								oldToNewPlacemarkDirection1,
								newToOldPlacemarkDirection1,
								oldToNewPlacemarkDirection2,
								newToOldPlacemarkDirection2
							])
							 */
						case .failure(let failure):
							XCTFail("Fail with error:  \(failure)")
					}
 
					exp.fulfill()
				}
		wait(for: [exp], timeout: 0.5)
	}
	
	
	func test_fetchDirections_failsWhenAtLeastOneRequestFail() {
		
		let sut = DataManager { source, destination, completion in
			completion(.failure(NSError(domain: "Any", code: 0)))
		}
		
		let exp = expectation(description: "Wait for fetch completion")
		exp.expectedFulfillmentCount = 1
		sut.fetchDirections(
				ofNew: SCPlacemark(),
				toOld: [SCPlacemark()],
				current: nil) { result in
					 
					switch result {
						case .success:
							XCTFail("Should have fail but succeeded")
							
						case .failure: break
					}
					
					exp.fulfill()
				}
		wait(for: [exp], timeout: 0.1)
	}
	
	func test_fetchDirections_doesntDeadLockWhenFetcherDispatchToTheMainThread() {
		
		let sut = DataManager { source, destination, completion in
			DispatchQueue.main.async {
				completion(.success([MKRoute()]))
			}
		}
		
		let exp = expectation(description: "Wait for fetch completion")
		exp.expectedFulfillmentCount = 1
		sut.fetchDirections(
				ofNew: SCPlacemark(),
				toOld: [SCPlacemark()],
				current: nil) { result in
					 
					switch result {
						case .success:
							break
							
						case .failure:
							XCTFail("Should have fail")
					}
					
					exp.fulfill()
				}
		wait(for: [exp], timeout: 0.1)
	}
	
	func test_fetchDirections_completsOnMainThread () {
		
		let sut = DataManager { source, destination, completion in
			DispatchQueue.global().async {
				completion(.success([MKRoute()]))
			}
		}
		
		let exp = expectation(description: "Wait for fetch completion")
		exp.expectedFulfillmentCount = 1
		sut.fetchDirections(
				ofNew: SCPlacemark(),
				toOld: [SCPlacemark()],
				current: nil) { result in 
					XCTAssertTrue(Thread.isMainThread)
					exp.fulfill()
				}
		wait(for: [exp], timeout: 0.1)
	}
}
