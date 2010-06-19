//
//  SGCommitLogTests.m
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
//  Created by Derek Smith.
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
