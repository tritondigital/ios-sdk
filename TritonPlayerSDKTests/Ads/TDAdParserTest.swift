//
//  TDAdParserTest.swift
//  TritonPlayerSDK
//
//  Created by mrk on 2016-11-14.
//  Copyright © 2016 Triton Digital. All rights reserved.
//

import Foundation
import XCTest

class TDAdParserTest: XCTestCase{
    
    
    func testTDAdParserHttpsSupport(){
        
        
        class MockTDAdParser: TDAdParser{
            
            override func start(with data: Data!) {
                let resultUserData = TDAd();
                if( data.count != 3 ){
                    resultUserData.format = "data"
                }else {
                    resultUserData.format = "url"
                }
                self.callbackBlock(resultUserData, nil)
               
            }
					
				  override func downloadData(from url: URL!, withCompletionHandler completionHandler: ((Data?, Error?) -> Void)!) {
						let result = "url".data(using: String.Encoding.utf8)!
						completionHandler(result,nil)
					}
            
        }
			
        
        let mockTDAdParser = MockTDAdParser();

        mockTDAdParser?.parse(fromRequest: "http://uneUrlVerte.com", completionBlock: {(userData, error) -> () in
            XCTAssertEqual(error?.localizedDescription, "The url is invalid or is not secured.")
        })
        
        mockTDAdParser?.parse(fromRequest: "https://uneUrlVerte.com", completionBlock: {(userData, error) -> () in
            XCTAssertEqual(userData?.format, "url")
        })
        
        mockTDAdParser?.parse(fromRequest: "<data></data>", completionBlock: {(userData, error) -> () in
            XCTAssertEqual(userData?.format, "data")
        })
        
    }
    
}
