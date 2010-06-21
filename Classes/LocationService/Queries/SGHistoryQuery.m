//
//  SGHistoryQuery.m
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

#import "SGHistoryQuery.h"

@implementation SGHistoryQuery
@synthesize recordId, layer, cursor, limit, requestId;

- (id) initWithRecord:(id<SGRecordAnnotation>)record
{
    if(self = [super init]) {
        recordId = [record recordId];
        layer = [record layer];
        cursor = nil;
        limit = 10;
        requestId = nil;
    }
    
    return self;
}

- (NSMutableDictionary*) params
{
    NSMutableDictionary* params = [NSMutableDictionary dictionary];
    if(cursor)
        [params setObject:cursor forKey:@"cursor"];
    
    if(limit > 0)
        [params setObject:[NSString stringWithFormat:@"%i", limit] forKey:@"limit"];
    
    return params; 
}

- (NSString*) uri
{
    return [NSString stringWithFormat:@"/records/%@/%@/history.json", layer, recordId];
}

- (void) dealloc
{
    [recordId release];
    [layer release];
    
    if(cursor)
        [cursor release];
    
    [requestId release];
    
    [super dealloc];
}

@end
