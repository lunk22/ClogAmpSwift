//
//  PlaylistSongItem.h
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 16.11.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PlaylistSongItem : NSObject {
	NSString *title;
	NSString *fileName;
	int duration;
    int order;
}

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *fileName;
@property (nonatomic, readwrite) int duration;
@property (nonatomic, readwrite) int order;
@end
