//
//  TDBannerView.swift
//  TritonPlayerSDK
//
//  Created by mrk on 2016-11-16.
//  Copyright © 2016 Triton Digital. All rights reserved.
//

import Foundation
import XCTest


protocol MyProtocol: TDBannerViewDelegate {
	
	func bannerView(_ bannerView: TDBannerView!, didFailToPresentAdWithError error: Error!)
	
	func bannerViewDidPresentAd(_ bannerView: TDBannerView!)
	
}

class TDAdBannerViewTest: XCTestCase, MyProtocol{
	
	
	var theExpectation:XCTestExpectation?
	var errorResult = "";
	var didFinished = false;
	
	func bannerViewDidPresentAd(_ bannerView: TDBannerView!) {
		didFinished = true;
		theExpectation?.fulfill();
		
	}
	
	
	func bannerView(_ bannerView: TDBannerView!, didFailToPresentAdWithError error: Error!) {
		errorResult = error.localizedDescription;
		theExpectation?.fulfill();
	}
	

    func testTDBannerWebViewNoHttpSupport(){
			
			theExpectation = expectation(description: "Init Expectation" )
			
			let ad = TDAd();
			let banner = TDCompanionBanner();
			banner.contentURL = URL(fileURLWithPath: "http://www.iabuk.net/sites/default/files/728x90.png");
			var banners = [TDCompanionBanner]();
			banners.append(banner)
			ad.companionBanners = banners  ;
			let tdBannerView:TDBannerView = TDBannerView(width: 728, andHeight: 90);
			tdBannerView.delegate = self;
			tdBannerView.present(ad);
			waitForExpectations(timeout: 1, handler: nil)
			assert(errorResult == "Only https is supported")
			
    }
	
    func testTDBannerWebViewHttpsSupport(){
        
			theExpectation = expectation(description: "Init Expectation" )
  
			let ad = TDAd();
			let banner = TDCompanionBanner();
			banner.contentURL = URL(string: "https://www.iabuk.net/sites/default/files/728x90.png");
			var banners = [TDCompanionBanner]();
			banners.append(banner)
			ad.companionBanners = banners  ;
			let tdBannerView:TDBannerView = TDBannerView(width: 300, andHeight: 50);
			tdBannerView.delegate = self;
			tdBannerView.present(ad);
			waitForExpectations(timeout: 10, handler: nil)
			assert(didFinished == true);
        
    }
	
    
    
}
