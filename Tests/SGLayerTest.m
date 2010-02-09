//
//  SGLayerTest.m
//  SGClient
//
//  Created by Derek Smith on 12/17/09.
//  Copyright 2010 SimpleGeo. All rights reserved.
//

#import "SGLocationServiceTests.h"
#import "SGClient.h"

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
    [self.locatorService addDelegate:layer];
    
    SGRecord* r = [self createRandomRecord];
    [layer addRecordAnnotation:r];
    STAssertTrue([[layer recordAnnotations] count] == 1, @"Should be one record in the layer.");
    
    [self addRecord:r responseId:[layer updateAllRecords]];
    [self.locatorService.operationQueue waitUntilAllOperationsAreFinished];    
    WAIT_FOR_WRITE();
    
    double oldLat = r.latitude;
    r.latitude = 1000.0;

    [self retrieveRecord:r responseId:[layer retrieveAllRecords]];
    [self.locatorService.operationQueue waitUntilAllOperationsAreFinished]; 
    
    STAssertEquals(r.latitude, oldLat, @"The expected lat should be %f, but was %f", oldLat, r.latitude);
    [self deleteRecord:r responseId:[self.locatorService deleteRecordAnnotation:r]];
    
    
    [layer removeAllRecordAnnotations];
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
        
    [layer addRecordAnnotations:records];
    STAssertTrue([[layer recordAnnotations] count] == amount, @"The layer should have %i records registered.", amount);
    [self addRecord:records responseId:[layer updateAllRecords]];
    
    WAIT_FOR_WRITE();
    WAIT_FOR_WRITE();
    
    [self.locatorService.operationQueue waitUntilAllOperationsAreFinished];
    
    [self retrieveRecord:records responseId:[self.locatorService retrieveRecordAnnotations:records]];
    [self.locatorService.operationQueue waitUntilAllOperationsAreFinished];
    
    NSDictionary* geoJSONObject = (NSDictionary*)recentReturnObject;
    STAssertNotNil(geoJSONObject, @"Return object should not be nil.");
    
    NSArray* features = [geoJSONObject features];
    STAssertNotNil(features, @"Features should be defined.");
    STAssertTrue([records count] == 20, @"There should be 20 records returned.");
    
    [self deleteRecord:records responseId:[self.locatorService deleteRecordAnnotations:records]];
    
    STAssertFalse([layer recordAnnotationCount] == amount - 1, @"There should be %i records.", amount - 1);
    [layer removeRecordAnnotation:[records lastObject]];
    STAssertTrue([layer recordAnnotationCount] == amount - 1, @"There should be %i records.", amount - 1);
    
    [layer removeAllRecordAnnotations];
    STAssertTrue([[layer recordAnnotations] count] == 0, @"There should be no records.");
    STAssertNil([layer updateAllRecords], @"No records means no response id");
    
}

- (void) testLayerInformation
{
    NSString* layerName = kSGTesting_Layer;

    [self.requestIds setObject:[self expectedResponse:YES message:@"Should be able to retrieve layer information" record:[NSNull null]]
                        forKey:[self.locatorService layerInformation:layerName]];

    [self.locatorService.operationQueue waitUntilAllOperationsAreFinished];
    
    NSDictionary* jsonObject = (NSDictionary*)recentReturnObject;
    
    STAssertNotNil(jsonObject, @"There should be information about the layer.");
    STAssertTrue([layerName isEqualToString:[jsonObject objectForKey:@"name"]], @"The JSON object should not be missing a name.");
    
    
}

@end
