//
//  SGLocationTypes.m
//  CCLocatorServices
//
//  Created by Derek Smith on 9/15/09.
//  Copyright 2010 SimpleGeo. All rights reserved.
//

#import "SGLocationTypes.h"

SGGeohash SGGeohashMake(double latitude, double longitude, int precision) {
    
    SGGeohash region = {latitude, longitude, precision};
    
    return region;

}