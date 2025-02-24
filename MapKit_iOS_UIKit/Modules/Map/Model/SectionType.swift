//
//  SectionType.swift
//  MapKit_iOS_UIKit
//
//  Created by sudhir on 05/02/25.
//

import Foundation

enum SectionType: Int, CaseIterable {
	case result = 0
	case source = 1
	case destination = 2
	
	var title: String {
		switch self {
			case .result: "Result"
			case .source: "Source"
			case .destination: "Destination"
		}
	}
}
