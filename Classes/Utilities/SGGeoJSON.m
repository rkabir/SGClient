//
//  SGGeoJSON.m
//  SGStalker
//
//  Created by Derek Smith on 6/16/10.
//  Copyright 2010 SimpleGeo. All rights reserved.
//

#import "SGGeoJSON.h"

NSMutableDictionary* SGGeometryCollectionCreate() {
    NSMutableDictionary* geometryCollection = [NSMutableDictionary dictionary];
    [geometryCollection setType:@"GeometryCollection"];
    [geometryCollection setGeometries:[NSMutableArray array]];
    return geometryCollection;
}

NSDictionary* SGGeometryCollectionAppend(NSDictionary* collection1, NSDictionary* collection2) {
    NSMutableArray* geometries = [NSMutableArray arrayWithArray:[collection1 geometries]];
    [geometries addObjectsFromArray:[collection2 geometries]];
    NSMutableDictionary* geometryCollection = [NSMutableDictionary dictionaryWithDictionary:collection1];
    [geometryCollection setGeometries:geometries];
    return geometryCollection;
}

NSDictionary* SGPointCreate(double lat, double lon) {
    NSDictionary* point = [NSDictionary dictionaryWithObjectsAndKeys:
                           @"Point", @"type",
                           [NSArray arrayWithObjects:
                            [NSNumber numberWithDouble:lon],
                            [NSNumber numberWithDouble:lat],
                            nil], @"coordinates",
                           nil];
    return point;
}