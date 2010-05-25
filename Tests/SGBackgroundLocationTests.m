//
//  SGBackgroundLocationTests.m
//  SGClient
//
//  Created by Derek Smith on 5/24/10.
//  Copyright 2010 SimpleGeo. All rights reserved.
//

#import "SGLocationServiceTests.h"

#if __IPHONE_4_0 >= __IPHONE_OS_VERSION_MAX_ALLOWED

@interface SGBackgroundLocationTests : SGLocationServiceTests
{
    
}

@end

@implementation SGBackgroundLocationTests

- (void) testBecameActive
{
    
}

- (void) testEnterBackground
{
    SGRecord* record = [self createRandomRecord];
    for(int i = 0; i < 10; i++)
        [self addRecordResponseId:[self.locatorService updateRecordAnnotation:record]];
    [self deleteRecordResponseId:[self.locatorService deleteRecordAnnotation:record]];
    
    [self.locatorService enterBackground];
    int remainingOperations = [[self.locatorService.operationQueue operations] count];
     STAssertTrue(remainingOperations == 0, @"There should be no operations in the queue. (%i)", remainingOperations);
}

@end

#endif