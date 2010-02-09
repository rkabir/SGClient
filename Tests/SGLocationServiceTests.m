//
//  LocatorTests.m
//  SGLocatorServices
//
//  Created by Derek Smith on 6/22/09.
//  Copyright 2010 Crash Corp. All rights reserved.
//

#import "SGLocationServiceTests.h"

@implementation SGLocationServiceTests

@synthesize locatorService, requestIds, recentReturnObject;

- (void) setUp
{
        
    locatorService = [SGLocationService sharedLocationService];
    STAssertNotNil(locatorService, @"Shared locator service should be created.");
    
    requestIds = [[NSMutableDictionary alloc] init];
    
    [locatorService addDelegate:self];
    [locatorService setHTTPAuthorizer:[[SGOAuth alloc] initWithKey:kSGOAuth_Key secret:kSGOAuth_Secret]];
    [SGLocationService callbackOnMainThread:NO];
}

- (void) addRecord:(NSObject*)record responseId:(NSString*)responseId
{
    [self.requestIds setObject:[self expectedResponse:YES message:@"Should be able to add the record" record:record]
                        forKey:responseId];

}

- (void) deleteRecord:(NSObject*)record responseId:(NSString*)responseId
{
    [self.requestIds setObject:[self expectedResponse:YES
                                              message:@"Record should be deleted."
                                               record:record]
                        forKey:responseId];    
}

- (void) retrieveRecord:(NSObject*)record responseId:(NSString*)responseId
{
    [self.requestIds setObject:[self expectedResponse:YES message:@"Should be able to retrieve the record" record:record]
                        forKey:responseId];
}


#pragma mark -
#pragma mark SGLocationService delegate methods 
 

- (void) locationService:(SGLocationService*)service succeededForResponseId:(NSString*)responseId responseObject:(NSArray*)objects
{
    NSDictionary* expectedResponse = [requestIds objectForKey:responseId];

    if(expectedResponse && objects) {
        
        recentReturnObject = [objects retain];
        
        SGRecord* record = [expectedResponse objectForKey:@"record"];
        if(record) {
            
            BOOL success = [[expectedResponse objectForKey:@"success"] boolValue];
            NSString* message = [expectedResponse objectForKey:@"message"];
            STAssertTrue(success, message);

        }
        
        [requestIds removeObjectForKey:responseId];
    } 
}

- (void) locationService:(SGLocationService*)service failedForResponseId:(NSString*)requestId error:(NSError*)error
{
    NSDictionary* expectedResponse = [requestIds objectForKey:requestId];
    if(expectedResponse && error) {
    
        recentReturnObject = nil;
        BOOL success = [[expectedResponse objectForKey:@"success"] boolValue];
        NSString* message = [expectedResponse objectForKey:@"message"];
        STAssertFalse(success, @"%@ %@", message, error);
                      
        [requestIds removeObjectForKey:requestId];
    }
}


#pragma mark -
#pragma mark Helper methods 
 

- (NSDictionary*) expectedResponse:(BOOL)succeed message:(NSString*)message record:(NSObject*)record
{
    NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithBool:succeed], @"success",
                                message, @"message",
                                record, @"record",
                                nil];
    
    return dictionary;
}
- (SGRecord*) createRandomRecord
{
    SGRecord* record = [[SGRecord alloc] init];
    record.type = kSGLocationType_Object;
    record.layer = kSGTesting_Layer;
    record.expires = [[NSDate distantFuture] timeIntervalSince1970];
    record.created = [[NSDate date] timeIntervalSince1970]; 
    record.longitude = rand() % 50 * (0.1231) + (double)(rand() % 50);
    record.latitude = rand() % 50 * (0.1721) + (double)(rand() % 50);
    record.recordId = [NSString stringWithFormat:@"%i", rand() % 10000000000];

    return record;
}

- (SGRecord*) createCopyOfRecord:(SGRecord*)record
{
    SGRecord* copy = [[SGRecord alloc] init];
    
    copy.type = record.type;
    copy.layer = record.layer;
    copy.expires = record.expires;
    copy.created = record.created;
    copy.longitude = record.longitude;
    copy.latitude = record.latitude;
    copy.recordId = record.recordId;    
    
    return copy;
}

- (BOOL) isRecord:(SGRecord*)firstRecord equalToRecord:(SGRecord*)secondRecord
{
    BOOL areEqual = YES;
    
    areEqual &= [firstRecord.recordId isEqualToString:secondRecord.recordId];
    areEqual &= firstRecord.longitude == secondRecord.longitude;
    areEqual &= firstRecord.latitude == secondRecord.latitude;    
    areEqual &= firstRecord.expires == secondRecord.expires;    
    areEqual &= firstRecord.created == secondRecord.created; 
    areEqual &= [firstRecord.type isEqualToString:secondRecord.type];
    areEqual &= [firstRecord.layer isEqualToString:secondRecord.layer];
        
    return areEqual;
}

- (void) tearDown
{
    
    [locatorService.operationQueue waitUntilAllOperationsAreFinished];
    STAssertTrue([[locatorService.operationQueue operations] count] == 0, @"There should be 0 operations in the queue");
    
    STAssertTrue([requestIds count] == 0, @"Tearing down tests too soon");
    [requestIds removeAllObjects];
    
    if(recentReturnObject) {
        
        [recentReturnObject release];
        recentReturnObject = nil;
        
    }
}

@end
