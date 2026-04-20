//
//  SongHistoryItem.m
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 13.02.19.
//

#import "SongHistoryItem.h"

@implementation SongHistoryItem

//@synthesize selectToPrint;
@synthesize title;
@synthesize artist;
@synthesize file;
@synthesize date;

- (id)init {
    self = [super init];
    if (self) {
//        selectToPrint = false;
        title         = nil;
        artist        = nil;
        file          = nil;
        date          = nil;
    }
    return self;
}

@end
