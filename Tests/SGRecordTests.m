//
//  SGRecordTests.m
//  SGClient
//
//  Created by Derek Smith on 11/15/09.
//  Copyright 2010 SimpleGeo. All rights reserved.
//


#import "SGLocationServiceTests.h"

@interface SGRecordTests : SGLocationServiceTests {
    
}

@end


@implementation SGRecordTests

- (void) testRecordCreation
{
    SGRecord* record = [self createRandomRecord];
    record.recordId = @"1";
    [self addRecord:record responseId:[self.locatorService updateRecordAnnotation:record]];
    
    SGRecord* record1 = [self createRandomRecord];
    record1.recordId = @"2";
    [self addRecord:record1 responseId:[self.locatorService updateRecordAnnotation:record1]];
    
    STAssertTrue([[self.locatorService.operationQueue operations] count] == 2, @"There should be 2 operations in the queue");   
    [self.locatorService.operationQueue waitUntilAllOperationsAreFinished];
    
    STAssertTrue([[self.locatorService.operationQueue operations] count] == 0, @"There should be 0 operations in the queue");       
    WAIT_FOR_WRITE();
    
    [self deleteRecord:record responseId:[self.locatorService deleteRecordAnnotation:record]];
    [self deleteRecord:record1 responseId:[self.locatorService deleteRecordAnnotation:record1]];
    
    SGRecord* dumbRecord = [self createCopyOfRecord:record];
    dumbRecord.recordId = @"6666";
    [self.requestIds setObject:[self expectedResponse:NO message:@"Record should not be present." record:dumbRecord]
                    forKey:[self.locatorService deleteRecordAnnotation:dumbRecord]];
    
    
    [record1 release];
    [record release];
    [dumbRecord release];
    
    [self.locatorService.operationQueue waitUntilAllOperationsAreFinished];
} 

- (void) testRecordFetch
{
    SGRecord* record = [self createRandomRecord];
    [self addRecord:record responseId:[self.locatorService updateRecordAnnotation:record]];    
    [self.locatorService.operationQueue waitUntilAllOperationsAreFinished];     
    WAIT_FOR_WRITE();
    
    NSInteger expectedId = [record.recordId intValue];
    [self retrieveRecord:record responseId:[self.locatorService retrieveRecord:record.recordId layer:record.layer]];    
    [self.locatorService.operationQueue waitUntilAllOperationsAreFinished];
    
    NSInteger recordId = [[(NSDictionary*)recentReturnObject id] intValue];
    STAssertEquals(recordId, expectedId, @"Expected %i recordId, but was %i", expectedId, recordId);
    
    [self deleteRecord:record responseId:[self.locatorService deleteRecordAnnotation:record]];
    [record release];    
} 

- (void) testRecordProperites
{
    SGRecord* record = [self createRandomRecord];
    
    NSMutableDictionary* properties = [NSMutableDictionary dictionaryWithDictionary:[record properties]];
    [properties setObject:@"Derek" forKey:@"name"];

    [self addRecord:record responseId:[self.locatorService updateRecord:record.recordId layer:record.layer coord:record.coordinate properties:properties]];    
    [self.locatorService.operationQueue waitUntilAllOperationsAreFinished];
    WAIT_FOR_WRITE();
    WAIT_FOR_WRITE();
    
    [self retrieveRecord:record responseId:[self.locatorService retrieveRecord:record.recordId layer:record.layer]];    
    [self.locatorService.operationQueue waitUntilAllOperationsAreFinished];
    
    NSDictionary* returnObject = (NSDictionary*)recentReturnObject;
    STAssertNotNil(returnObject, @"Object should be returned");
    NSString* name = [[returnObject objectForKey:@"properties"] objectForKey:@"name"];
    STAssertNotNil(name, @"Return object should conatin the key name.");
    STAssertTrue([name isEqualToString:@"Derek"], @"The name property should be equal to Derek");

    [record updateRecordWithGeoJSONObject:returnObject];
    STAssertTrue([[record.properties objectForKey:@"name"] isEqualToString:@"Derek"], @"The name of the record should be Derek.");

    [self deleteRecord:record responseId:[self.locatorService deleteRecordAnnotation:record]];
    [record release];    
}

- (void) testMultipleRecords
{
    NSArray* records = [NSArray arrayWithObjects:
                        [self createRandomRecord],
                        [self createRandomRecord],
                        [self createRandomRecord],
                        [self createRandomRecord],
                        [self createRandomRecord],
                        nil];
    
    [self addRecord:records responseId:[self.locatorService updateRecordAnnotations:records]];    
    [self.locatorService.operationQueue waitUntilAllOperationsAreFinished];
    WAIT_FOR_WRITE();
    
    [self retrieveRecord:records responseId:[self.locatorService retrieveRecordAnnotations:records]];    
    [self.locatorService.operationQueue waitUntilAllOperationsAreFinished];
    
    [self deleteRecord:records responseId:[self.locatorService deleteRecordAnnotations:records]];
}
 

- (void) testUpdateRecord
{
    SGRecord* record = [self createRandomRecord];
    
    [self addRecord:record responseId:[self.locatorService updateRecordAnnotation:record]];    
    [self.locatorService.operationQueue waitUntilAllOperationsAreFinished];
    
    double newLat = 10.01;
    record.latitude = newLat;
    [self addRecord:record responseId:[self.locatorService updateRecordAnnotation:record]];    
    [self.locatorService.operationQueue waitUntilAllOperationsAreFinished];
    WAIT_FOR_WRITE();
    
    record.latitude = -newLat;
    
    [self retrieveRecord:record responseId:[self.locatorService retrieveRecordAnnotation:record]];
    [self.locatorService.operationQueue waitUntilAllOperationsAreFinished];

    STAssertNotNil(recentReturnObject, @"Record retrieval should return an object.");
    double lat = [[(NSDictionary*)recentReturnObject coordinates] latitude];

    STAssertEquals(lat, newLat, @"Expected record lat to be %f, but was %f.", lat, newLat);

    [self deleteRecord:record responseId:[self.locatorService deleteRecordAnnotation:record]];
    [record release];
}

- (void) testRecordFetchByType
{
    NSArray* types = [NSArray arrayWithObjects:kSGLocationType_Place, kSGLocationType_Person, kSGLocationType_Object, nil];
    NSMutableArray* addedRecords = [NSMutableArray array];
    for(NSString* type in types) {
                      
    
        SGRecord* p1 = [self createRandomRecord];
        SGRecord* p2 = [self createRandomRecord];
    
        p1.type = type;
        p2.type = type;
        
        CLLocationCoordinate2D coord = {10.0, 10.0};
        NSArray* records = [NSArray arrayWithObjects:p1, p2, nil];
        for(SGRecord* record in records) {
        
            record.latitude = coord.latitude;
            record.longitude = coord.longitude;
        
        }
        
        [addedRecords addObject:p1];
        [addedRecords addObject:p2];
        
        [self addRecord:records responseId:[self.locatorService updateRecordAnnotations:records]];
        [self.locatorService.operationQueue waitUntilAllOperationsAreFinished];
        
        WAIT_FOR_WRITE();
     
        [self retrieveRecord:records responseId:[self.locatorService retrieveRecordsForCoordinate:coord
                                                                                           radius:10.0
                                                                                           layers:[NSArray arrayWithObject:p1.layer]
                                                                                            types:[NSArray arrayWithObject:type]
                                                                                            limit:100]];
    
        [self.locatorService.operationQueue waitUntilAllOperationsAreFinished];
        STAssertNotNil(recentReturnObject, @"Nearby request should return some records");

        NSArray* features = [(NSDictionary*)recentReturnObject features];
        STAssertNotNil(features, @"Features should be defined with the return object");
        
        NSInteger returnAmount = [features count];
        STAssertTrue(returnAmount >= 2, [@"Should return two records but was " stringByAppendingFormat:@"%i", returnAmount]);
        BOOL equalTypes = NO;
        for(NSDictionary* retrievedRecord in features) {
            
            equalTypes = [[[retrievedRecord objectForKey:@"properties"] objectForKey:@"type"] isEqualToString:type];
            STAssertTrue(equalTypes, @"Incorrect type found. Record should be of type %@", type);
        }
    }
    
    [self.locatorService.operationQueue waitUntilAllOperationsAreFinished];    
    [self deleteRecord:addedRecords responseId:[self.locatorService deleteRecordAnnotations:addedRecords]];
}

- (void) testNearbyRecords
{
    SGRecord* r1 = [self createRandomRecord];
    SGRecord* r2 = [self createRandomRecord];
    
    r1.latitude = 20.01;
    r1.longitude = 20.01;
    r2.latitude = 20.011;
    r2.longitude = 20.011;
    
    NSArray* records = [NSArray arrayWithObjects:r1, r2, nil];
    [self addRecord:records responseId:[self.locatorService updateRecordAnnotations:records]];    
    [self.locatorService.operationQueue waitUntilAllOperationsAreFinished];
    WAIT_FOR_WRITE();
    
    SGGeohash region = SGGeohashMake(r1.latitude, r1.longitude, 2);
    [self retrieveRecord:records responseId:[self.locatorService retrieveRecordsForGeohash:region
                                                                                   layers:[NSArray arrayWithObject:r1.layer]
                                                                                    types:[NSArray arrayWithObjects:r1.type, r2.type, nil]
                                                                                    limit:10]];    
    [self.locatorService.operationQueue waitUntilAllOperationsAreFinished];
    NSDictionary* geoJSONObject = (NSDictionary*)recentReturnObject;

    STAssertNotNil(geoJSONObject, @"Return object should be valid");
    NSArray* features = [geoJSONObject features];
    STAssertNotNil(features, @"The GeoJSONObject should define features.");
    int returnAmount = [features count];
    STAssertTrue(returnAmount != 0, [@"Should return two records but was " stringByAppendingFormat:@"%i", returnAmount]);
    
    recentReturnObject = nil;
    
    CLLocationCoordinate2D coord = {20.01, 20.01};
    [self retrieveRecord:records responseId:[self.locatorService retrieveRecordsForCoordinate:coord
                                                                                       radius:1000 
                                                                                       layers:[NSArray arrayWithObject:r1.layer]
                                                                                        types:[NSArray arrayWithObjects:r1.type, r2.type, nil]
                                                                                        limit:100]];

    [self.locatorService.operationQueue waitUntilAllOperationsAreFinished];
    
    geoJSONObject = (NSDictionary*)recentReturnObject;
    STAssertNotNil(geoJSONObject, @"Return object should be valid");
    features = [geoJSONObject features];
    STAssertNotNil(features, @"The GeoJSONObject should define features.");
    returnAmount = [features count];
    STAssertTrue(returnAmount != 0, [@"Should return two records but was " stringByAppendingFormat:@"%i", returnAmount]);
        
    [self deleteRecord:records responseId:[self.locatorService deleteRecordAnnotations:records]];
}

@end
