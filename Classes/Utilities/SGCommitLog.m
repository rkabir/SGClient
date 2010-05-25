//
//  SGCommitLog.m
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

#import "SGCommitLog.h"

#import "SGCacheHandler.h"

@interface SGCommitLog (Private)

- (void) expandUsername:(NSString *)username key:(NSString *)key;

- (void) addValue:(NSString*)value data:(NSData*)data username:(NSString*)username key:(NSString*)key;
- (void) incrementCommitCountForUsername:(NSString*)username key:(NSString*)key;
- (void) decrementCommitCountForUsername:(NSString*)username key:(NSString*)key;
- (void) incrementErrorCountForUsername:(NSString*)username key:(NSString*)key;
- (void) decrementErrorCountForUsername:(NSString*)username key:(NSString *)key;
- (void) incrementValue:(NSString*)value username:(NSString*)username key:(NSString*)key;
- (void) decrementValue:(NSString*)value username:(NSString*)username key:(NSString*)key;
- (int) getCountForValue:(NSString*)value username:(NSString*)username key:(NSString*)key;

@end

@implementation SGCommitLog
@synthesize delegate, flushTimeInterval;

- (id) initWithName:(NSString*)name
{
    if(self = [super init]) {
        cacheHandler = [[SGCacheHandler alloc] initWithDirectory:name];
        
        commitLogLock = [[NSLock alloc] init];
        flushTimer = nil;
        flushTimeInterval = 10.0;
        
        commitLog = [[NSMutableDictionary alloc] init];
        delegate = nil;
    }
    
    return self;
}

- (void) startFlushTimer
{
    if(!flushTimer)
        flushTimer = [[NSTimer timerWithTimeInterval:flushTimeInterval
                                              target:self 
                                            selector:@selector(flush) 
                                            userInfo:nil
                                             repeats:YES] retain];
}

- (void) stopFlushTimer
{
    if(flushTimer) {
        [flushTimer release];
        flushTimer = nil;
    }
}

NSComparisonResult dateSort(NSString *s1, NSString *s2, void *context) {
    s1 = [[s1 componentsSeparatedByString:@"-"] objectAtIndex:1];
    s2 = [[s2 componentsSeparatedByString:@"-"] objectAtIndex:1];
    NSDate* d1 = [NSDate dateWithTimeIntervalSince1970:[s1 doubleValue]];
    NSDate* d2 = [NSDate dateWithTimeIntervalSince1970:[s2 doubleValue]];
    return [d1 compare:d2];
}

- (void) flush
{
    [commitLogLock lock];
    [cacheHandler changeToTopLevelPath];
    NSDictionary* logs, *logValues = nil;
    for(NSString* username in commitLog) {
        [cacheHandler changeDirectory:username];

        logs = [commitLog objectForKey:username];
        for(NSString* logKey in logs) {
            [cacheHandler changeDirectory:logKey];
            logValues = [commitLog objectForKey:logKey];
            
            for(NSString* key in logValues)
                [cacheHandler updateFile:key withContents:[logValues objectForKey:key]];
            
            [cacheHandler changeToParentDirectory];
        }
        [cacheHandler changeToParentDirectory];
    }
    [commitLogLock unlock];
}

- (void) clear 
{
    [commitLog removeAllObjects];
}

- (void) reload
{
    [commitLogLock lock];
    [cacheHandler changeToTopLevelPath];
    NSArray* usernames = [cacheHandler getFiles];
    for(NSString* username in usernames) {
        [cacheHandler changeDirectory:username];
        NSArray* keys = [cacheHandler getFiles];
        for(NSString* key in keys) {
            [self expandUsername:username key:key];  
            [cacheHandler changeDirectory:key];
            NSArray* files = [cacheHandler getFiles];
            for(NSString* file in files) {
                NSData* data = [cacheHandler getContentsOfFile:file];
                [[[commitLog objectForKey:username] objectForKey:key] setObject:data forKey:file];
            }
            [cacheHandler changeToParentDirectory];
        }
        [cacheHandler changeToParentDirectory];
    }
    [commitLogLock unlock];
}

- (void) replay:(NSString*)username
{
    [self flush];
    [self clear];
    [self reload];
    
    if(delegate) {
        NSDictionary* keyLogs = nil;
        NSArray* files = nil;
        [cacheHandler changeDirectory:username];
        keyLogs = [commitLog objectForKey:username];
        for(NSString* keyLog in keyLogs) {
            [cacheHandler changeDirectory:keyLog];
            files = [cacheHandler getFiles];
            for(NSString* file in files)
                if(delegate)
                    [delegate commitLog:self
                                 replay:[cacheHandler getContentsOfFile:file]
                               username:username
                                    key:keyLog];
            [cacheHandler changeToParentDirectory];
        }
        [cacheHandler changeToParentDirectory];
        [self deleteUsername:username];
    }
    
    [self clear];
}

- (void) addCommit:(NSData*)data forUsername:(NSString*)username andKey:(NSString*)key
{
    [self addValue:@"commit" data:data username:username key:key];
}

- (void) addError:(NSData*)data forUsername:(NSString*)username andKey:(NSString*)key
{
    [self addValue:@"error" data:data username:username key:key];
}

- (void) addValue:(NSString*)value data:(NSData*)data username:(NSString*)username key:(NSString*)key
{
    [commitLogLock lock];
    [self expandUsername:username key:key];
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
    NSString* newKey = [NSString stringWithFormat:@"%@-%f", value, timeInterval];
    [[[commitLog objectForKey:username] objectForKey:key] setObject:data forKey:newKey];
    [self incrementCommitCountForUsername:username key:key];
    [commitLogLock unlock];
}

- (void) deleteAllUsernames
{
    [cacheHandler changeToTopLevelPath];
    NSArray* usernames = [cacheHandler getFiles];
    for(NSString* username in usernames)
        [self deleteUsername:username];
}

- (void) deleteUsername:(NSString*)username
{
    [cacheHandler changeToTopLevelPath];
    [cacheHandler deleteDirectory:username];
    
    if([commitLog objectForKey:username])
        [commitLog removeObjectForKey:username];
}

- (void) deleteUsername:(NSString*)username key:(NSString*)key
{
    [cacheHandler changeToTopLevelPath];
    [cacheHandler changeDirectory:username];
    [cacheHandler deleteDirectory:key];
    
    if([commitLog objectForKey:username])
        if([[commitLog objectForKey:username] objectForKey:key])
            [[commitLog objectForKey:username] removeObjectForKey:key];
}

- (NSDictionary*) getAllCommitsForUsername:(NSString*)username
{
    NSMutableDictionary* commits = [NSMutableDictionary dictionary];
    NSDictionary* userDictionary = [commitLog objectForKey:username];
    for(NSString* keyLogs in userDictionary) {
        [commits setObject:[self getCommitsForUsername:username key:keyLogs] forKey:keyLogs];
    }
    
    return commits;
}

- (NSMutableDictionary*) getCommitsForUsername:(NSString*)username key:(NSString*)key
{
    NSDictionary* userDictionary = [commitLog objectForKey:username];
    if(userDictionary) {
        NSDictionary* keyLogs = [userDictionary objectForKey:key];
        if(keyLogs) {
            NSMutableDictionary* keyLog = [NSMutableDictionary dictionaryWithDictionary:keyLogs];
            [keyLog removeObjectForKey:@"commit_count"];
            [keyLog removeObjectForKey:@"error_count"];
            
            // TODO: We want to sort the keys by timestamp here
            
            return keyLog;
        }
    }
    
    return nil;
}

- (int) getCommitCountForUsername:(NSString*)username key:(NSString*)key
{
    return [self getCountForValue:@"commit_count" username:username key:key];
}

- (int) getErrorCountForUsername:(NSString*)username key:(NSString*)key
{
    return [self getCountForValue:@"error_count" username:username key:key];
}

#pragma mark -
#pragma mark Utility methods 

- (void) incrementCommitCountForUsername:(NSString*)username key:(NSString*)key
{
    [self incrementValue:@"commit_count" username:username key:key];
}

- (void) decrementCommitCountForUsername:(NSString*)username key:(NSString*)key
{
    [self decrementValue:@"commit_count" username:username key:key];
}

- (void) incrementErrorCountForUsername:(NSString*)username key:(NSString*)key
{
    [self incrementValue:@"error_count" username:username key:key];
}

- (void) decrementErrorCountForUsername:(NSString*)username key:(NSString *)key
{
    [self decrementValue:@"error_count" username:username key:key];
}

- (void) incrementValue:(NSString*)value username:(NSString*)username key:(NSString*)key
{
    NSMutableDictionary* userDictionary = [commitLog objectForKey:username];
    if(userDictionary) {
        NSMutableDictionary* keyDictionary = [userDictionary objectForKey:key];
        if(keyDictionary) {
            NSNumber* number = [keyDictionary objectForKey:value];
            if(number)
                number = [NSNumber numberWithInt:[number intValue] + 1];
            else
                number = [NSNumber numberWithInt:0];
            [keyDictionary setObject:number forKey:value];
        }
    }
}

- (void) decrementValue:(NSString*)value username:(NSString*)username key:(NSString*)key
{
    NSMutableDictionary* userDictionary = [commitLog objectForKey:username];
    if(userDictionary) {
        NSMutableDictionary* keyDictionary = [userDictionary objectForKey:key];
        if(keyDictionary) {
            NSNumber* number = [keyDictionary objectForKey:value];
            if(number)
                number = [NSNumber numberWithInt:[number intValue] - 1];
            else
                number = [NSNumber numberWithInt:0];
            [keyDictionary setObject:number forKey:value];
        }
    }    
}

- (int) getCountForValue:(NSString*)value username:(NSString*)username key:(NSString*)key
{
    NSDictionary* userDictionary = [commitLog objectForKey:username];
    if(userDictionary) {
        NSDictionary* keyDictionary = [userDictionary objectForKey:key];
        if(keyDictionary) {
            NSNumber* number = [keyDictionary objectForKey:value];
            if(number)
                return [number intValue];
        }
    }

    return 0;
}

- (void) expandUsername:(NSString*)username key:(NSString*)key
{
    NSMutableDictionary* userDictionary = [commitLog objectForKey:username];
    if(userDictionary) {
        if(![userDictionary objectForKey:key]) {
            NSDictionary* keyDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                           [NSNumber numberWithInt:0], @"commit_count",
                                           [NSNumber numberWithInt:0], @"error_count",
                                           nil];            
            [userDictionary setObject:keyDictionary forKey:key];
        }
    } else {
        userDictionary = [NSMutableDictionary dictionary];
        NSDictionary* keyDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       [NSNumber numberWithInt:0], @"commit_count",
                                       [NSNumber numberWithInt:0], @"error_count",
                                       nil];
        [userDictionary setObject:keyDictionary forKey:key];
        [commitLog setObject:userDictionary forKey:username];
    }
}

- (void) dealloc
{
    [self stopFlushTimer];
    [commitLogLock release];
    [cacheHandler release];
    [super dealloc];
}

@end
