/*
 *  SGLocationServiceTests.h
 *  SGClient
 *
 *  Created by Derek Smith on 11/15/09.
 *  Copyright 2010 SimpleGeo. All rights reserved.
 */

#import <SenTestingKit/SenTestingKit.h>

#import "SGClient.h"
#import "SGTestingMacros.h"

// Delay requests after writes to give them a chance to be 
// registered.
#define WAIT_FOR_WRITE()              sleep(10)

@interface SGLocationServiceTests : SenTestCase <SGLocationServiceDelegate> {
    
    SGLocationService* locatorService;
    NSMutableDictionary* requestIds;
    NSObject* recentReturnObject;
}

@property (nonatomic, retain) SGLocationService* locatorService;
@property (nonatomic, retain) NSMutableDictionary* requestIds;
@property (nonatomic, retain) NSObject* recentReturnObject;

- (NSDictionary*) expectedResponse:(BOOL)succeed message:(NSString*)message record:(NSObject*)record;

- (SGRecord*) createCopyOfRecord:(SGRecord *)record;
- (SGRecord*) createRandomRecord;

- (void) deleteRecord:(NSObject*)record responseId:(NSString*)responseId;
- (void) addRecord:(NSObject*)record responseId:(NSString*)responseId;
- (void) retrieveRecord:(NSObject*)record responseId:(NSString*)responseId;

@end
