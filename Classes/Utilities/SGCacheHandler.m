//
//  SGCacheHandler.m
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

#import "SGCacheHandler.h"

@interface SGCacheHandler (Private)

- (NSString*) getFilePath:(NSString*)file;

@end

@implementation SGCacheHandler
@synthesize cachePath, ttl, topLevelCachePath;

- (id) initWithDirectory:(NSString*)directory
{
    if(self = [super init]) {
        ttl = 604800;
        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        cachePath = [[paths objectAtIndex:0] retain];
        [self changeDirectory:directory];
        topLevelCachePath = [cachePath retain];
        [self clearStaleCacheFiles];
    }
    
    return self;
}

- (void) changeDirectory:(NSString*)directory
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    cachePath = [[cachePath stringByAppendingPathComponent:directory] retain];
    if(![fileManager fileExistsAtPath:cachePath])
        [fileManager createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:nil];
}

- (void) deleteDirectory:(NSString*)directory
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    directory = [self getFilePath:directory];
    NSError* error = nil;
    if([fileManager fileExistsAtPath:directory]) {
        [fileManager removeItemAtPath:directory error:&error];
    }
    
    if(error)
        SGLog(@"SGCacheHandler - %@", [error description]);
}

- (void) changeToParentDirectory
{
    cachePath = [[cachePath stringByDeletingLastPathComponent] retain];
}

- (void) changeToTopLevelPath
{
    cachePath = topLevelCachePath;
}

- (NSArray*) getFiles
{
    return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:cachePath error:nil];
}

- (void) clearStaleCacheFiles
{
    NSArray* files = [self getFiles];
    NSFileManager* fileManager = [NSFileManager defaultManager];

    NSDate* modified = nil;
    NSDictionary* attributes = nil;
    NSError* error = nil;
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    NSString* filePath = nil;
    for(NSString* file in files) {
        filePath = [cachePath stringByAppendingPathComponent:file];
        attributes = [fileManager attributesOfItemAtPath:filePath error:&error];

        if(!error) {
            modified = [attributes objectForKey:NSFileModificationDate];
            if(([modified timeIntervalSince1970] + ttl) < currentTime) {
                error = nil;
                [fileManager removeItemAtPath:filePath error:&error];
            }
        }
        error = nil;
    }    
}

- (void) deleteAllFiles
{
    [self changeToTopLevelPath];
    NSArray* files = [self getFiles];
    for(NSString* file in files)
        [self deleteDirectory:file];
}

- (NSData*) getContentsOfFile:(NSString*)file
{
    return [NSData dataWithContentsOfFile:[self getFilePath:file]];
}

- (BOOL) updateFile:(NSString*)file withContents:(NSData*)data
{
    BOOL valid = YES;
    if(![[self getFiles] containsObject:file])
        [[NSFileManager defaultManager] createFileAtPath:[self getFilePath:file] contents:data attributes:nil];
    else
        valid = [data writeToFile:[self getFilePath:file] atomically:NO];

    return valid;
}

- (NSString*) getFilePath:(NSString*)file
{
    return [cachePath stringByAppendingPathComponent:file];
}

- (void) dealloc
{
    [topLevelCachePath release];
    [cachePath release];
    [super dealloc];
}

@end
