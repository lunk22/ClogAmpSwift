//
//  Database.h
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 13.02.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

#ifndef Database_h
#define Database_h

@interface Database : NSObject

+ (NSString *)getDBPath;

+ (bool)buildDatabaseTablesIfNeeded;

+ (bool)insertIntoCuesheetAssignment:(NSString *)fileName assignedPDFPath:(NSString *)pdfPath;

+ (bool)deleteFromCuesheetAssignment:(NSString *)fileName;

+ (bool)insertSongIntoHistory:(NSString *)songTitle withArtist:(NSString *)songArtist withPath:(NSString *)songPath;

+ (NSString *)getAssignedPDF:(NSString *)fileName;

+ (NSArray *)getPlaylists;

+ (NSArray *)getSongHistory:(NSDate *)fromDate toDate:(NSDate *)toDate;

+ (int)addPlaylist:(NSString *)desc withContPlayback:(bool)contPlayback;

+ (bool)updatePlaylist:(int)plID withDesc:(NSString *)desc withContPlayback:(bool)contPlayback withPause:(int)pause withOrder:(int)order;

+ (bool)addSongToPlaylist:(int)plID withTitle:(NSString *)title withDuration:(int)duration withFileName:(NSString *)fileName withOrder:(int)orderIndex;

+ (bool)updateSongOrderInPlaylist:(int)plID withTitle:(NSString *)title withDuration:(int)duration withFileName:(NSString *)fileName withOrder:(int)orderIndex;

+ (bool)removeSongFromPlaylist:(int)plID withTitle:(NSString *)title withDuration:(int)duration withFileName:(NSString *)fileName;

+ (NSArray *)getPlaylistSongs:(int)playlistID;

+ (bool)deletePlaylist:(int)plID;

@end

#endif /* Database_h */
