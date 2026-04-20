//
//  Playlist.m
//  ClogAmpMac
//
//  Created by Pascal Roessel on 2/18/13.
//
//

#import "Playlist.h"
#import "Database.h"

@implementation Playlist

@synthesize plID;
@synthesize pause;
@synthesize order;
@synthesize contPlayback;
@synthesize description;

- (void)setDescription:(NSString *)newValue{
    description = newValue;
    [Database updatePlaylist:[self plID] withDesc:newValue withContPlayback:[self contPlayback] withPause:[self pause] withOrder:[self order]];
}

- (void)setContPlayback:(bool)newValue{
    contPlayback = newValue;
    [Database updatePlaylist:[self plID] withDesc:[self description] withContPlayback:newValue withPause:[self pause] withOrder:[self order]];
}

- (void)setPause:(int)newValue{
    pause = newValue;
    [Database updatePlaylist:[self plID] withDesc:[self description] withContPlayback:[self contPlayback] withPause:newValue withOrder:[self order]];
    
}

- (void)setOrder:(int)newValue{
    order = newValue;
    [Database updatePlaylist:[self plID] withDesc:[self description] withContPlayback:[self contPlayback] withPause:[self pause] withOrder:newValue];
    
}

- (id)init
{
    self = [super init];
    if (self) {
        description = nil;
        order       = 99;
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    
}

- (id)initWithCoder:(NSCoder *)aCoder{
    return [self init];
}

- (id)initExistingPlaylist:(int)pl withDesc:(NSString *)desc withContPlayback:(bool)cp withPause:(int)p withOrder:(int)o{
    self = [self init];
    if (self) {
        plID         = pl;
        description  = desc;
        contPlayback = cp;
        pause        = p;
        order        = o;
    }
    
    
    
    return self;
}

- (id)initNewPlaylistWithDesc:(NSString *)desc withOrder:(int)o{
    self = [self init];
    if (self) {
        description  = desc;
        order        = o;
        plID         = [Database addPlaylist:desc withContPlayback:false];
        [Database updatePlaylist:plID withDesc:description withContPlayback:false withPause:0 withOrder:order];
    }
    
    
    return self;
}

@end
