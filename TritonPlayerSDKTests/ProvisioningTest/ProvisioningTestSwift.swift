//
//  ProvisioningTestSwift.swift
//  TritonPlayerSDK
//
//  Created by mrk on 2016-11-10.
//  Copyright © 2016 Triton Digital. All rights reserved.
//

import XCTest
import CoreData


class ProvisioningTestSwift: XCTestCase{
    
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
         super.tearDown()
    }
    
    func testsProvisioning(){
        
        
        class MockNSManagedObjectContext: LiveStreamProvisioningParser {
            
            override func getProvisioningXMLData(forCallsign inCallSign: String!, referrerURL inReferrerURL: String!) -> Data! {
                let testBundle = Bundle(for: ProvisioningTestSwift.self)
                let sourcePath = testBundle.path( forResource: "livestreamHttps", ofType: "xml")
                let xmlData = try! NSData(contentsOfFile: sourcePath!) as Data
                
                return xmlData
            }
        }

        
        let liveStreamProvisioningParserMock = MockNSManagedObjectContext();
        let provisioningTest:Provisioning = Provisioning();
        
        let result:Bool = (liveStreamProvisioningParserMock?.getProvisioningFor(provisioningTest, withCallSign: "KROQFM", referrerURL: "any"))!
        XCTAssertTrue(result);
        
        XCTAssertTrue(provisioningTest.mountPoints.count == 2, "Should contain 2 servers");
        XCTAssertTrue(provisioningTest.totalServers == 2, "totalServers should be equals to 2");
        
        let server  = provisioningTest.mountPoints[0]
        let serverUrls: NSArray = (server as AnyObject).value(forKey: "urls") as! NSArray;
        XCTAssertEqual(serverUrls[0] as! String, "https://64.86.101.196:443", "1st server[0] should be https://64.86.101.196:443");
        
    }
    
    
    
}

