//
//  SGGeoJSONEncoder.m
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

#import "SGGeoJSONEncoder.h"
#import "SGLocationTypes.h"
#import "GeoJSON+NSArray.h"
#import "GeoJSON+NSDictionary.h"
#import "SGGeoJSON+NSDictionary.h"
#import "SGRecord.h"

@implementation SGGeoJSONEncoder

+ (NSArray*) recordsForGeoJSONObject:(NSDictionary*)geojsonObject
{
    NSMutableArray* records = [NSMutableArray array];
    NSMutableArray* features = [NSMutableArray array];
    if([geojsonObject isFeatureCollection])
        [features addObjectsFromArray:[geojsonObject features]];
    else
        [features addObject:geojsonObject];

    for(NSDictionary* feature in features) {
        SGRecord* record = [SGGeoJSONEncoder recordForGeoJSONObject:feature];
        if(record)
            [records addObject:record];
    }

    return records;
}

+ (SGRecord*) recordForGeoJSONObject:(NSDictionary*)geojsonObject
{
    SGRecord* record = nil;
    if(!record) {
        record = [[[SGRecord alloc] init] autorelease];
        [record updateRecordWithGeoJSONObject:geojsonObject];
    }
    
    return record;
}

+ (NSMutableDictionary*) geoJSONObjectForRecordAnnotations:(NSArray*)recordAnnotations
{
    NSMutableDictionary* geoJSONObject = nil;
    if(recordAnnotations && [recordAnnotations count]) {
        
        geoJSONObject = [NSMutableDictionary dictionary];
        [geoJSONObject setType:@"FeatureCollection"];
        
        NSMutableArray* features = [NSMutableArray array];
        for(id<SGRecordAnnotation> recordAnnotation in recordAnnotations) {
            NSDictionary* geoJSON = [SGGeoJSONEncoder geoJSONObjectForRecordAnnotation:recordAnnotation];
            if(geoJSON)
                if([geoJSON isFeatureCollection])
                    [features addObjectsFromArray:[geoJSON features]];
                else
                    [features addObject:geoJSON];
        }
        
        [geoJSONObject setFeatures:features];
    }

    return geoJSONObject;
}

+ (NSMutableDictionary*) geoJSONObjectForRecordAnnotation:(id<SGRecordAnnotation>)recordAnnotation
{
    NSMutableDictionary* feature = nil;
    if([recordAnnotation isKindOfClass:[NSDictionary class]])
        feature = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary*)recordAnnotation];
    else if(recordAnnotation) {
        feature = [NSMutableDictionary dictionary];
        [feature setType:@"Feature"];
    
        NSDictionary* properties = [recordAnnotation properties];
        [properties setValue:[recordAnnotation type] forKey:@"type"];
        [feature setProperties:properties];
    
        NSMutableArray* coordinates = [NSMutableArray arrayWithObjects:[NSNumber numberWithDouble:0.0],
                                       [NSNumber numberWithDouble:0.0], nil];
        [coordinates setLatitude:[recordAnnotation coordinate].latitude];
        [coordinates setLongitude:[recordAnnotation coordinate].longitude];
        NSMutableDictionary* geometry = [NSMutableDictionary dictionary];
        [geometry setType:@"Point"];
        [geometry setCoordinates:coordinates];
        [feature setValue:geometry forKey:@"geometry"];
    
        [feature setRecordId:[recordAnnotation recordId]];
        [feature setExpires:[recordAnnotation expires]];
        [feature setCreated:[recordAnnotation created]];
        [feature setLayer:[recordAnnotation layer]];
    }
               
    
    return feature;
}

#pragma mark -
#pragma mark Utilities 

// Example: http://api.simplegeo.com/layer/com.simplegeo.global.brightkite.json
+ (NSString*) layerNameFromLayerLink:(NSString*)layerLink
{
    NSString* endpoint = nil;
    if(layerLink) {
        // This is realllly bad.
        NSArray* components = [layerLink componentsSeparatedByString:@"/"];
        endpoint = [[components lastObject] stringByDeletingPathExtension];
    }
    
    return endpoint;
}

@end
