//
//  Utis.swift
//  MapKit_iOS_UIKit
//
//  Created by sudhir on 05/02/25.
//


func cprint<T>(_ value: T) -> T {
	print("Debug Value : -", value)
	return value
}

func cprint<T>(_ prefix: String, _ value: T) -> T {
	print(prefix, ": -", value)
	return value
}
