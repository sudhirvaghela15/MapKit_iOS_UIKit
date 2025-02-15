//
//  Loader.swift
//  MVVMDemo
//
//  Created by sudhir on 26/06/22.
//

import UIKit
extension LoadingView {
    static func showLoadingView() {
        DispatchQueue.main.async {
			let windowView = UIApplication.shared.keyWindow
            if let loadingView = windowView?.viewWithTag(LoadingView.tagValue) as? LoadingView {
                loadingView.isLoading = true
            } else {
                let loadingView = LoadingView(frame: UIScreen.main.bounds)
                windowView?.addSubview(loadingView)
                loadingView.isLoading = true
            }
        }
    }

    static func hideLoadingView() {
        DispatchQueue.main.async {
			let windowView = UIApplication.shared.keyWindow
            windowView?.viewWithTag(LoadingView.tagValue)?.removeFromSuperview()
        }
    }
}

extension UIApplication {
	
	var keyWindow: UIWindow? {
		// Get connected scenes
		return self.connectedScenes
			// Keep only active scenes, onscreen and visible to the user
			.filter { $0.activationState == .foregroundActive }
			// Keep only the first `UIWindowScene`
			.first(where: { $0 is UIWindowScene })
			// Get its associated windows
			.flatMap({ $0 as? UIWindowScene })?.windows
			// Finally, keep only the key window
			.first(where: \.isKeyWindow)
	}
	
}

