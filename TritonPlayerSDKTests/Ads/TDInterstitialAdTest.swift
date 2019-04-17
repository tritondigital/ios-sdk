//
//  TDBannerView.swift
//  TritonPlayerSDK
//
//  Created by mrk on 2016-11-16.
//  Copyright © 2016 Triton Digital. All rights reserved.
//

import Foundation
import XCTest

class TDInterstitialTest: XCTestCase{
	
	class MockViewController: UIViewController{
		
		var presentViewControllerInvoked = false;
		
		override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
			self.presentViewControllerInvoked = true;
		}
		
		public func checkPresentViewControllerInvokation()->Bool {
			return self.presentViewControllerInvoked;
		}
		
	}
	
	func testTDInterstitialSupportForHttps(){
		
		let ad = TDAd();
		let viewController = MockViewController();
		let interstitialAd = TDInterstitialAd();
		
		ad.mediaURL = URL(string: "https://www.iabuk.net/sites/default/files/728x90.png")
		interstitialAd.load(ad)
		interstitialAd.present(from: viewController)
		
		assert(viewController.checkPresentViewControllerInvokation() == true, "should support https in interstitial media" )
		
	}
	
	
	func testTDInterstitialNoSupportForHttp(){
		
		let ad = TDAd();
		let viewController = MockViewController();
		let interstitialAd = TDInterstitialAd();
		
		ad.mediaURL = URL(string: "http://www.iabuk.net/sites/default/files/728x90.png")
		interstitialAd.load(ad)
		interstitialAd.present(from: viewController)
		
		assert(viewController.checkPresentViewControllerInvokation() == false, "should not support http in interstitial media" )
		
	}
	
	
}
