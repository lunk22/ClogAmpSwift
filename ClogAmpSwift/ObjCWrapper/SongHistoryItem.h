//
//  SongHistoryItem.h
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 13.02.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SongHistoryItem : NSObject {
//    bool      selectToPrint;
	NSString *title;
	NSString *artist;
	NSString *file;
	NSDate   *date;
}

//@property (nonatomic, readwrite) bool selectToPrint;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *artist;
@property (nonatomic, retain) NSString *file;
@property (nonatomic, retain) NSDate *date;
@end
