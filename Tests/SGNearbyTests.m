//
//  SGBenchMarkTests.m
//  SGClient
//
//  Copyright (c) 2009-2010, SimpleGeo
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without 
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, 
//  this list of conditions and the following disclaimer. Redistributions 
//  in binary form must reproduce the above copyright notice, this list of
//  conditions and the following disclaimer in the documentation and/or 
//  other materials provided with the distribution.
//  
//  Neither the name of the SimpleGeo nor the names of its contributors may
//  be used to endorse or promote products derived from this software 
//  without specific prior written permission.
//   
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS 
//  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
//  GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
//  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//

#import "SGLocationServiceTests.h"
#import "SGLatLonNearbyQuery.h"

@interface SGNearbyTests : SGLocationServiceTests
{
    
}

@end

@implementation SGNearbyTests
- (void) testNearbyDistanceSort
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

    [self addRecordResponseId:[self.locationService updateRecordAnnotations:records]];    
    [SGLocationServiceTests waitForWrite];
    [self.locationService.operationQueue waitUntilAllOperationsAreFinished];
    
    SGLatLonNearbyQuery* query = [[SGLatLonNearbyQuery alloc] initWithLayer:kSGTesting_Layer];
    query.coordinate = coord;
    query.radius = 10.0;
    query.layer = kSGTesting_Layer;
    query.limit = 40;
    
    for(int i = 0; i < 10; i++) {
        recentReturnObject = nil;
        [self retrieveRecordResponseId:[self.locationService nearby:query]];     
        [self.locationService.operationQueue waitUntilAllOperationsAreFinished];
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
    
    [self deleteRecordResponseId:[self.locationService deleteRecordAnnotations:records]];
}


- (void) testNearbyTime
{
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970] - 5.0;
    NSTimeInterval weekLater = [[NSDate date] timeIntervalSince1970] + 60 * 40;

    CLLocationCoordinate2D coord = {10.0, 10.0};
    NSMutableArray* records = [NSMutableArray array];
    SGRecord* record = nil;
    for(int i = 0; i < 10; i++) {
        record = [self createRandomRecord];
        record.latitude = coord.latitude;
        record.longitude = coord.longitude;
        [records addObject:record];
    }    
        
    [self addRecordResponseId:[self.locationService updateRecordAnnotations:records]];    
    [SGLocationServiceTests waitForWrite];
    [self.locationService.operationQueue waitUntilAllOperationsAreFinished];
    
    SGLatLonNearbyQuery* query = [[SGLatLonNearbyQuery alloc] initWithLayer:kSGTesting_Layer];
    query.coordinate = coord;
    query.radius = 10.0;
    query.limit = 40;
    query.start = currentTime;
    query.end = weekLater;
    
    [self retrieveRecordResponseId:[self.locationService nearby:query]];
     
    [self.locationService.operationQueue waitUntilAllOperationsAreFinished];
    STAssertNotNil(recentReturnObject, @"Return object should not be nil");
    NSArray* features = (NSArray*)[recentReturnObject features];
    STAssertNotNil(features, @"Features should be returned");
    STAssertTrue([features count] >= 1, @"There should be more than 10 records that are returned.");
     
    query.start = currentTime * 2.0;
    query.end = weekLater * 2.0;
    [self retrieveRecordResponseId:[self.locationService nearby:query]];     
    
    [self.locationService.operationQueue waitUntilAllOperationsAreFinished];
    features = [recentReturnObject features];
    STAssertTrue([features count] == 0, @"No features should be returned");
    
    query.start = currentTime;
    query.end = weekLater + 120;
    [self retrieveRecordResponseId:[self.locationService nearby:query]];

    [self.locationService.operationQueue waitUntilAllOperationsAreFinished];
    STAssertNotNil(recentReturnObject, @"Return object should not be nil");
    features = (NSArray*)[recentReturnObject features];
    STAssertNotNil(features, @"Features should be returned");
    STAssertTrue([features count] >= 1, @"There should be more than 10 records that are returned.");
    
    [query release];
    [self deleteRecordResponseId:[self.locationService deleteRecordAnnotations:records]];
}

- (void) testNearbyPagination
{
    CLLocationCoordinate2D coord = {10.0, 10.0};
    NSMutableArray* records = [NSMutableArray array];
    SGRecord* record = nil;
    for(int i = 0; i < 10; i++) {
        record = [self createRandomRecord];
        record.latitude = coord.latitude;
        record.longitude = coord.longitude;
        [records addObject:record];
    }    
    
    [self addRecordResponseId:[self.locationService updateRecordAnnotations:records]];    
    [self.locationService.operationQueue waitUntilAllOperationsAreFinished];
    [SGLocationServiceTests waitForWrite];
    
    SGLatLonNearbyQuery* query = [[SGLatLonNearbyQuery alloc] initWithLayer:kSGTesting_Layer];
    query.coordinate = coord;
    query.radius = 1.0;
    query.limit = 1;
    
    [self retrieveRecordResponseId:[self.locationService nearby:query]];
    [self.locationService.operationQueue waitUntilAllOperationsAreFinished];
    STAssertTrue([[recentReturnObject features] count] == 1, @"A single record should be returned.");
    
    NSString* cursor = [recentReturnObject objectForKey:@"next_cursor"];
    STAssertNotNil(cursor, @"A cursor should be returned to enable pagination.");
    
    query.cursor = cursor;
    query.limit = 9;
    
    [self retrieveRecordResponseId:[self.locationService nearby:query]];
    [self.locationService.operationQueue waitUntilAllOperationsAreFinished];
    STAssertTrue([[recentReturnObject features] count] == 9, @"Another 9 records should be returned.");
    
    [query release];
    [self deleteRecordResponseId:[self.locationService deleteRecordAnnotations:records]];
}

- (void) testNearbyIPAddress
{
    SGIPAddressQuery* query = [[SGIPAddressQuery alloc] initWithLayer:@"com.simplegeo.us.business"];
    query.ipAddress = @"173.164.32.245";
    [self retrieveRecordResponseId:[self.locationService nearby:query]];
    [SGLocationServiceTests waitForWrite];
    STAssertTrue([recentReturnObject isFeatureCollection], @"A feature colleciton should be returned.");    
    for(NSDictionary* feature in [recentReturnObject features])
        STAssertTrue([[[feature properties] objectForKey:@"city"] isEqualToString:@"Denver"], @"The business listings should be from Denver");
}

- (void) testReverseGeocoder
{
    CLLocationCoordinate2D coords = {40.017294990861913, -105.27759999949176};
    NSString* responseId = [self.locationService reverseGeocode:coords];
    
    [self.requestIds setObject:[self expectedResponse:YES message:@"Should return a reverse geocode object."]
                        forKey:responseId];
    [self.locationService.operationQueue waitUntilAllOperationsAreFinished];

    STAssertNotNil(recentReturnObject, @"Reverse geocoder should return an object.");
    NSDictionary* properties = [(NSDictionary*)recentReturnObject objectForKey:@"properties"];
    STAssertNotNil(properties, @"GeoJSON object should contain a properties field.");
    STAssertTrue([properties count] == 9, @"There should be 9 key/value pairs in the properties dictionary.");
    STAssertTrue([[properties objectForKey:@"country"] isEqualToString:@"US"], @"The country code should be US.");
}

@end
