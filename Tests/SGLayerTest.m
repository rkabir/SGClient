//
//  SGLayerTest.m
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
#import "SGLocationServiceTests.h"
#import "SGClient.h"
#import "SGLatLonNearbyQuery.h"

static NSString* testingLayer = kSGTesting_Layer;

@interface SGLayerTest : SGLocationServiceTests {
    
}

@end


@implementation SGLayerTest


- (void) testLayerCreation
{
    SGLayer* layer = [[SGLayer alloc] initWithLayerName:testingLayer];
    STAssertTrue([layer.layerId isEqualToString:testingLayer], @"Layer names should be equal");
    STAssertTrue([[layer recordAnnotations] count] == 0, @"Records should be empty");
}

- (void) testLayerFetching
{
    SGLayer* layer = [[SGLayer alloc] initWithLayerName:kSGTesting_Layer];
    [self.locationService addDelegate:layer];
    
    SGRecord* r = [self createRandomRecord];
    [layer addRecordAnnotation:r update:NO];
    STAssertTrue([[layer recordAnnotations] count] == 1, @"Should be one record in the layer.");
    
    [self addRecordResponseId:[layer updateAllRecords]];
    [self.locationService.operationQueue waitUntilAllOperationsAreFinished];    
    [SGLocationServiceTests waitForWrite];
    
    double oldLat = r.latitude;
    r.latitude = 1000.0;

    [self retrieveRecordResponseId:[layer retrieveAllRecords]];
    [self.locationService.operationQueue waitUntilAllOperationsAreFinished]; 
    
    STAssertEquals(r.latitude, oldLat, @"The expected lat should be %f, but was %f", oldLat, r.latitude);
    [self deleteRecordResponseId:[self.locationService deleteRecordAnnotation:r]];
    
    
    [layer removeAllRecordAnnotations:NO];
    STAssertNil([layer retrieveAllRecords], @"No records means no response id");

}

- (void) testAddingRecords
{
    SGLayer* layer = [[SGLayer alloc] initWithLayerName:testingLayer];
    
    int amount = 20;
    NSMutableArray* records = [NSMutableArray array];
    SGRecord* record = nil;
    for(int i = 0; i < amount; i++) {
        record = [self createRandomRecord];
        record.recordId = [NSString stringWithFormat:@"sg-%i", i];
        [records addObject:record];
    }
        
    [layer addRecordAnnotations:records update:NO];
    STAssertTrue([[layer recordAnnotations] count] == amount, @"The layer should have %i records registered.", amount);
    [self addRecordResponseId:[layer updateAllRecords]];
    [SGLocationServiceTests waitForWrite];
    [self.locationService.operationQueue waitUntilAllOperationsAreFinished];
    
    [layer removeAllRecordAnnotations:NO];
    
    [self retrieveRecordResponseId:[layer retrieveRecordAnnotations:records]];
    [self.locationService.operationQueue waitUntilAllOperationsAreFinished];
    
    NSDictionary* geoJSONObject = (NSDictionary*)recentReturnObject;
    STAssertNotNil(geoJSONObject, @"Return object should not be nil.");
    
    NSArray* features = [geoJSONObject features];
    STAssertNotNil(features, @"Features should be defined.");
    STAssertTrue([records count] == 20, @"There should be 20 records returned.");
    
    STAssertFalse([layer recordAnnotationCount] == amount - 1, @"There should be %i records.", amount - 1);
    [layer removeRecordAnnotation:[records lastObject] update:YES];
    STAssertTrue([layer recordAnnotationCount] == 0, @"There should be %i records.", amount - 1);
    
    [layer removeAllRecordAnnotations:YES];
    STAssertTrue([[layer recordAnnotations] count] == 0, @"There should be no records.");
    STAssertNil([layer updateAllRecords], @"No records means no response id");
}

- (void) testLayerInformation
{
    NSString* layerName = kSGTesting_Layer;

    [self.requestIds setObject:[self expectedResponse:YES message:@"Should be able to retrieve layer information"]
                        forKey:[self.locationService layerInformation:layerName]];

    [self.locationService.operationQueue waitUntilAllOperationsAreFinished];
    
    NSDictionary* jsonObject = (NSDictionary*)recentReturnObject;
    
    STAssertNotNil(jsonObject, @"There should be information about the layer.");
    STAssertTrue([layerName isEqualToString:[jsonObject objectForKey:@"name"]], @"The JSON object should not be missing a name.");
}

- (void) testNearby
{
    SGLayer* layer = [[SGLayer alloc] initWithLayerName:testingLayer];
    
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970] - 5.0;
    NSTimeInterval weekLater = [[NSDate date] timeIntervalSince1970] + 60 * 40;
    
    CLLocationCoordinate2D coords = {54.0,54.0};
    int amount = 20;
    NSMutableArray* records = [NSMutableArray array];
    SGRecord* record = nil;
    for(int i = 0; i < amount; i++) {
        record = [self createRandomRecord];
        record.recordId = [NSString stringWithFormat:@"sg-%i", i];
        
        if(i % 2) {
         
            record.latitude = coords.latitude;
            record.longitude = coords.longitude;
        }
        
        [records addObject:record];
    }
    
    [layer addRecordAnnotations:records update:NO];
    STAssertTrue([[layer recordAnnotations] count] == amount, @"The layer should have %i records registered.", amount);
    [self addRecordResponseId:[layer updateAllRecords]];
    
    [SGLocationServiceTests waitForWrite];
    [SGLocationServiceTests waitForWrite];
    
    [self.locationService.operationQueue waitUntilAllOperationsAreFinished];
    
    SGLatLonNearbyQuery* query = [[SGLatLonNearbyQuery alloc] initWithLayer:testingLayer];
    query.coordinate = coords;
    query.radius = 10.0;
    query.limit = 25;
    query.start = currentTime;
    query.end = weekLater;
    
    [self retrieveRecordResponseId:[self.locationService nearby:query]];     
    
    [self.locationService.operationQueue waitUntilAllOperationsAreFinished];
    STAssertNotNil(recentReturnObject, @"Return object should not be nil");
    NSArray* features = (NSArray*)[recentReturnObject features];
    STAssertNotNil(features, @"Features should be returned");
    amount = [features count];
    STAssertTrue(amount >= 1, @"%i records were returned but was expecting more than 1.", amount);
    
    query.start = currentTime * 2.0;
    query.end = weekLater * 2.0;
    [self retrieveRecordResponseId:[self.locationService nearby:query]];     

    [self.locationService.operationQueue waitUntilAllOperationsAreFinished];
    features = [recentReturnObject features];
    STAssertTrue([features count] == 0, @"No features should be returned");
    
    [self deleteRecordResponseId:[self.locationService deleteRecordAnnotations:records]];
    [self.locationService.operationQueue waitUntilAllOperationsAreFinished];
    [layer release];
}

- (void) testNextNearby
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
     SGLayer* layer = [[SGLayer alloc] initWithLayerName:testingLayer];
    
    [self addRecordResponseId:[layer updateRecordAnnotations:records]];    
    [self.locationService.operationQueue waitUntilAllOperationsAreFinished];
    [SGLocationServiceTests waitForWrite];
    
    SGLatLonNearbyQuery* query = [[SGLatLonNearbyQuery alloc] initWithLayer:kSGTesting_Layer];
    query.coordinate = coord;
    query.radius = 1.0;
    query.limit = 1;
    
    [self retrieveRecordResponseId:[layer nearby:query]];
    [self.locationService.operationQueue waitUntilAllOperationsAreFinished];
    STAssertTrue([[recentReturnObject features] count] == 1, @"A single record should be returned.");
    
    STAssertNotNil(layer.recentNearbyQuery.cursor, @"A new cursor should have been applied to the layer object.");
    
    layer.recentNearbyQuery.limit = 9;
    [self retrieveRecordResponseId:[layer nextNearby]];
    [self.locationService.operationQueue waitUntilAllOperationsAreFinished];
    STAssertTrue([[recentReturnObject features] count] == 9, @"Another 9 records should be returned.");
    
    [self deleteRecordResponseId:[self.locationService deleteRecordAnnotations:records]];
    [query release];
    [layer release];
}

@end
