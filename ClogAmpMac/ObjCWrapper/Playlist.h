//
//  Playlist.h
//  ClogAmpMac
//
//  Created by Pascal Roessel on 2/18/13.
//
//

#import <Foundation/Foundation.h>

@interface Playlist : NSObject{
//	int plID;
//    int pause;
//    int order;
//
//	bool contPlayback;
//
//	NSString *description;
}

@property (nonatomic, readwrite) int plID;
@property (nonatomic, readwrite) int pause;
@property (nonatomic, readwrite) int order;

@property (nonatomic, readwrite) bool contPlayback;

@property (nonatomic, readwrite) NSString *description;

- (id)initWithCoder:(NSCoder *)aCoder;

- (id)initExistingPlaylist:(int)pl withDesc:(NSString *)desc withContPlayback:(bool)cp withPause:(int)p withOrder:(int)o;
- (id)initNewPlaylistWithDesc:(NSString *)desc withOrder:(int)o;

@end
