//
//  PlaylistSongItem.m
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 16.11.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

#import "PlaylistSongItem.h"

@implementation PlaylistSongItem

@synthesize title;
@synthesize fileName;
@synthesize duration;
@synthesize order;

- (id)init {
    self = [super init];
    if (self) {
        title         = nil;
        fileName      = nil;
        duration      = 0;
        order         = 99999999;
    }
    return self;
}

@end
