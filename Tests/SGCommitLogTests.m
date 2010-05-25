//
//  SGCommitLogTests.m
//  SGClient
//
//  Created by Derek Smith on 5/24/10.
//  Copyright 2010 SimpleGeo. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "SGCommitLog.h"

@interface SGCommitLogTests : SenTestCase {
 
    SGCommitLog* commitLog;
    NSString* username;
    NSString* key;
    NSData* data;
}

@end

@implementation SGCommitLogTests

- (void) setUp
{
    commitLog = [[SGCommitLog alloc] initWithName:@"SGCommitLogTests"];
    username = @"arbok";
    key = @"attacks";
    data = [[@"{\"bite\":18}" dataUsingEncoding:NSASCIIStringEncoding] retain];
}

- (void) testAddCommit
{
    [commitLog addCommit:data forUsername:username andKey:key];
    data = [[@"{\"bite\":19}" dataUsingEncoding:NSASCIIStringEncoding] retain];
    [commitLog addCommit:data forUsername:username andKey:key];
    
    STAssertTrue([commitLog getCommitCountForUsername:username key:key] == 2, @"There should be two attacks.");
    STAssertFalse([commitLog getCommitCountForUsername:username key:key] == 19, @"There should be only two attacks.");
    STAssertTrue([commitLog getErrorCountForUsername:username key:key] == 0, @"There shoud not bes any errors.");
    
    NSDictionary* commits = [commitLog getAllCommitsForUsername:username];
    STAssertTrue([commits count] == 1, @"There should only be one key.");
    NSDictionary* keyDictionary = [commits objectForKey:key];
    STAssertNotNil(keyDictionary, @"The key dictionary should not be nil.");
    STAssertTrue([keyDictionary count] == 2, @"There should only be two keys.");
}

- (void) testFlushAndReload
{
    [commitLog addCommit:data forUsername:username andKey:key];
    [commitLog flush];
    [commitLog clear];
    
    NSDictionary* commits = [commitLog getAllCommitsForUsername:username];
    STAssertNotNil(commits, @"Commits should not be empty.");
    STAssertTrue([commits count] == 0, @"There should be no commits loaded into memory.");
    
    [commitLog reload];
    commits = [commitLog getAllCommitsForUsername:username];
    STAssertTrue([commits count] == 1, @"There should be one key.");
}

- (void) testDelete
{
    [commitLog addCommit:data forUsername:username andKey:key];
    NSString* badkey = @"bad_key";
    [commitLog addCommit:data forUsername:username andKey:badkey];
    [commitLog flush];
    
    [commitLog deleteUsername:username key:badkey];
    NSDictionary* commits = [commitLog getCommitsForUsername:username key:badkey];
    STAssertTrue([commits count] == 0, @"The deleted key should not be retrieved.");
    
    commits = [commitLog getAllCommitsForUsername:username];
    STAssertTrue([commits count] == 1, @"There should still be one commit.");
}

- (void) tearDown
{
    [commitLog deleteAllUsernames];
    [commitLog clear];
    [commitLog reload];
    NSDictionary* commits = [commitLog getAllCommitsForUsername:username];
    STAssertTrue([commits count] == 0, @"The cache should empty.");
    [username release];
    [key release];
    [data release];
}

@end
