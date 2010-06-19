//
//  SGGeoJSON.h
//  SGStalker
//
//  Created by Derek Smith on 6/16/10.
//  Copyright 2010 SimpleGeo. All rights reserved.
//

#import "GeoJSON+NSArray.h"
#import "GeoJSON+NSDictionary.h"

extern NSMutableDictionary* SGGeometryCollectionCreate();
extern NSDictionary* SGGeometryCollectionAppend(NSDictionary* collection1, NSDictionary* collection2);

extern NSDictionary* SGPointCreate(double lat, double lon);