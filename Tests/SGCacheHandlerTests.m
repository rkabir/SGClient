//
//  SGCacheHandlerTests.m
//  SGClient
//
//  Created by Derek Smith on 5/24/10.
//  Copyright 2010 SimpleGeo. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "SGCacheHandler.h"

@interface SGCacheHandlerTests : SenTestCase {
    
    SGCacheHandler* cacheHandler;
}

@end

@implementation SGCacheHandlerTests

- (void) setUp
{
    cacheHandler = [[SGCacheHandler alloc] initWithDirectory:@"SGCacheHandlerTest"];   
}

- (void) testChangeDirectory
{
    [cacheHandler changeDirectory:@"HelpDirectory"];
    STAssertTrue([[cacheHandler.cachePath lastPathComponent] isEqualToString:@"HelpDirectory"], @"The HelpDirectory should be included.");
}

- (void) testCacheUpdates
{
    [cacheHandler changeDirectory:@"CacheUpdates"];
    NSData* data = [@"THIS IS SOME DATA" dataUsingEncoding:NSASCIIStringEncoding];
    STAssertTrue([cacheHandler updateFile:@"MontyPython" withContents:data], @"File should be written successfully.");
    
    NSArray* files = [cacheHandler getFiles];
    STAssertTrue([files count] == 1, @"There should only be one file.");
    STAssertTrue([[files objectAtIndex:0] isEqualToString:@"MontyPython"], @"The name of the single file should be MontyPython.");
    data = [cacheHandler getContentsOfFile:@"MontyPython"];
    NSString* dataString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    STAssertTrue([dataString isEqualToString:@"THIS IS SOME DATA"], @"The data is not saved properly.");
    [dataString release];
}

- (void) testDeleteDirectory
{
    [cacheHandler changeDirectory:@"DeleteMe"];
    [cacheHandler changeDirectory:@"DeleteMeToo"];
    [cacheHandler changeToTopLevelPath];
    NSArray* files = [cacheHandler getFiles];
    STAssertTrue([files count] == 1, @"There should be one directory.");
    
    [cacheHandler deleteDirectory:@"DeleteMe"];
    files = [cacheHandler getFiles];
    STAssertTrue([files count] == 0, @"There should be no directories.");
}

- (void) tearDown
{
    [cacheHandler deleteAllFiles];
    [cacheHandler release];
}

@end
