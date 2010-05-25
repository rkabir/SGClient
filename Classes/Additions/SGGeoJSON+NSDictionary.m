//
//  SGGeoJSON+NSDictionary.m
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

#import "SGGeoJSON+NSDictionary.h"

@implementation NSDictionary (SGGeoJSONObject)

- (double) created
{
    double created = -1.0;
    if([self isFeature]) {
        NSNumber* num = [self objectForKey:@"created"];
        if(num)
            created = [num doubleValue];
    }
    
    return created;
}

- (double) expires
{
    double created = -1.0;
    if([self isFeature]) {
        
        NSNumber* num = [self objectForKey:@"expires"];
        if(num)
            created = [num doubleValue];
    }
    
    return created;    
}

- (NSString*) recordId
{
    NSString* objectId = nil;
    if([self isFeature])
        objectId = [self objectForKey:@"id"];
    
    return objectId;
}

- (NSString*) layer
{
    NSString* layer = nil;
    if([self isFeature])
        layer = [self objectForKey:@"layer"];
    
    return layer;
}

- (NSString*) layerLink
{
    NSString* layerLink = nil;
    if([self isFeature])
        layerLink = [[self objectForKey:@"layerLink"] objectForKey:@"href"];
    
    return layerLink;
}

- (NSString*) selfLink
{
    NSString* selfLink = nil;
    if([self isFeature])
        selfLink = [[self objectForKey:@"selfLink"] objectForKey:@"href"];
    
    return selfLink;
}

- (CLLocationCoordinate2D) coordinate
{
    NSArray* coordinate = [self coordinates];
    CLLocationCoordinate2D coord = {[[coordinate objectAtIndex:1] doubleValue], [[coordinate objectAtIndex:0] doubleValue]};
    return coord;
}

@end

@implementation NSMutableDictionary (SGGeoJSONObject)

- (void) setCreated:(double)created
{
    [self setObject:[NSNumber numberWithDouble:created]
             forKey:@"created"];
}

- (void) setExpires:(double)expires
{
    [self setObject:[NSNumber numberWithDouble:expires]
             forKey:@"expires"];
}

- (void) setRecordId:(NSString*)recordId
{
    [self setObject:recordId forKey:@"id"];
}

- (void) setLayer:(NSString*)layer
{
    [self setObject:layer forKey:@"layer"];
}

@end
