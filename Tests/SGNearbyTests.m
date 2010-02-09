//
//  SGBenchMarkTests.m
//  SGClient
//
//  Created by Derek Smith on 11/15/09.
//  Copyright 2010 SimpleGeo. All rights reserved.
//

#import "SGLocationServiceTests.h"

@interface SGNearbyTests : SGLocationServiceTests
{
    
}

@end

@implementation SGNearbyTests

- (void) testNearbyResponseTime
{
    CLLocationCoordinate2D coord = {10.0, 10.0};
    NSMutableArray* records = [NSMutableArray array];
    SGRecord* record = nil;
    for(int i = 0; i < 10; i++) 
    {
        record = [self createRandomRecord];
        record.latitude = coord.latitude;
        record.longitude = coord.longitude;
        [records addObject:record];
    }

    [self addRecord:records responseId:[self.locatorService updateRecordAnnotations:records]];    
    WAIT_FOR_WRITE();
    [self.locatorService.operationQueue waitUntilAllOperationsAreFinished];
    
    for(int i = 0; i < 10; i++) {
    
        recentReturnObject = nil;
        [self retrieveRecord:records responseId:[self.locatorService retrieveRecordsForCoordinate:coord
                                                                                           radius:100
                                                                                           layers:[NSArray arrayWithObject:kSGTesting_Layer]
                                                                                            types:nil
                                                                                            limit:100]];     
        [self.locatorService.operationQueue waitUntilAllOperationsAreFinished];
        STAssertNotNil(recentReturnObject, @"Return object should not be nil");
        
        NSArray* features = [(NSDictionary*)recentReturnObject features];
        STAssertNotNil(features, @"Features should be returned");
        
        int size = [features count];
        for(int j = 1; j < size; j++) {
            
            double d1 = [[[features objectAtIndex:j - 1] objectForKey:@"distance"] doubleValue];
            double d2 = [[[features objectAtIndex:j] objectForKey:@"distance"] doubleValue];
            
            STAssertTrue(d1 <= d2, @"Distance should be ordered ( %f > %f )", d1, d2);
        }
        
        STAssertTrue([(NSArray*)recentReturnObject count] > 0, @"Return amount should be greater than zero.");
    }
    
    [self deleteRecord:records responseId:[self.locatorService deleteRecordAnnotations:records]];
}

- (void) testReverseGeocoder
{
    CLLocationCoordinate2D coords = {40.017294990861913, -105.27759999949176};
    NSString* responseId = [self.locatorService reverseGeocode:coords];
    
    [self.requestIds setObject:[self expectedResponse:YES message:@"Should return a reverse geocode object." record:[NSNull null]]
                        forKey:responseId];
    [self.locatorService.operationQueue waitUntilAllOperationsAreFinished];

    STAssertNotNil(recentReturnObject, @"Reverse geocoder should return an object.");
    NSDictionary* properties = [(NSDictionary*)recentReturnObject objectForKey:@"properties"];
    STAssertNotNil(properties, @"GeoJSON object should contain a properties field.");
    STAssertTrue([properties count] == 9, @"There should be 9 key/value pairs in the properties dictionary.");
    STAssertTrue([[properties objectForKey:@"country"] isEqualToString:@"US"], @"The country code should be US.");
}

@end
