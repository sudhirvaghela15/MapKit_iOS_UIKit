//
//  Array+Extension.swift
//  MapKit_iOS_UIKit
//
//  Created by sudhir on 04/02/25.
//

import Foundation

extension Array {
	
    func decompose() -> (Iterator.Element, [Iterator.Element])? {
        guard let first = first else { return nil }
        return (first, Array(self[1..<count]))
    }
	
	///
	/// create tuple  array
	///
	func toTuple() -> [(Element, Element)] {
		var tuples: [(Element, Element)] = []
		
		for (index, object) in enumerated() where index != count - 1 {
			tuples.append((object, self[index + 1]))
		}

		return tuples
	}
}
