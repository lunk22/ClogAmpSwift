//
//  Database.m
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 13.02.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Database.h"
#import "sqlite3.h"
#import "SongHistoryItem.h"

@implementation Database

+ (NSString *)getDBPath{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = [fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
    NSURL *url = [paths firstObject];
    NSString *dbFolderPath = dbFolderPath = [[url path] stringByAppendingString:@"/ClogAmpSwift"];

    if ([fileManager fileExistsAtPath: dbFolderPath] == false){
        [fileManager createDirectoryAtPath:dbFolderPath withIntermediateDirectories:false attributes:nil error:nil];
    }
    
    NSString *dbPath = [dbFolderPath stringByAppendingString:@"/ClogAmpMacDB.db"];
    dbPath = [dbPath stringByExpandingTildeInPath];
    
    return dbPath;
}

+ (bool)buildDatabaseTablesIfNeeded{
    
    NSString *dbPath = [Database getDBPath];
    
    sqlite3 *database;
    int result;
    
    //Open database
    result = sqlite3_open([dbPath cStringUsingEncoding:NSUTF8StringEncoding], &database);
    if(result != SQLITE_OK){
        sqlite3_close(database);
        return false;
    }
    
//    //create table CuesheetAssignment
//    result = sqlite3_exec(database, "CREATE TABLE IF NOT EXISTS CuesheetAssignment (FileName TEXT PRIMARY KEY, CuesheetPath TEXT)", NULL, NULL, NULL);
//
//    if(result != SQLITE_OK){
//        sqlite3_close(database);
//        return false;
//    }
    
    //create table SongHistory
    result = sqlite3_exec(database, "CREATE TABLE IF NOT EXISTS SongHistory (Title TEXT, Artist TEXT, FileName TEXT, PlayedDate TEXT, PlayedTime TEXT, PRIMARY KEY (Title, Artist, FileName, PlayedDate, PlayedTime))", NULL, NULL, NULL);
    
    if(result != SQLITE_OK){
        sqlite3_close(database);
        return false;
    }
    
//    //Create table Playlist
//    result = sqlite3_exec(database, "CREATE TABLE IF NOT EXISTS Playlist (ID INTEGER PRIMARY KEY AUTOINCREMENT, Description TEXT, ContPlayback BOOLEAN, Pause INT, IOrder INT)", NULL, NULL, NULL); //, IOrder INT
//    
//    if(result != SQLITE_OK){
//        sqlite3_close(database);
//        return false;
//    }
//    
//    //Create table Playlist Songs
//    result = sqlite3_exec(database, "CREATE TABLE IF NOT EXISTS PlaylistSong (PID INTEGER, SongOrder INTEGER, SongTitle TEXT, SongFileName TEXT, SongDuration TEXT)", NULL, NULL, NULL);
//    
//    if(result != SQLITE_OK){
//        sqlite3_close(database);
//        return false;
//    }
    
    sqlite3_close(database);
    return true;
}

//+ (bool)insertIntoCuesheetAssignment:(NSString *)fileName assignedPDFPath:(NSString *)pdfPath{
//    sqlite3 *database;
//    int result;
//
//    result = sqlite3_open([[Database getDBPath] cStringUsingEncoding:NSUTF8StringEncoding], &database);
//    if(result != SQLITE_OK){
//        sqlite3_close(database);
//        return false;
//    }
//
//    NSString *exec = @"INSERT INTO CuesheetAssignment VALUES(\"";
//    exec = [exec stringByAppendingString:fileName];
//    exec = [exec stringByAppendingString:@"\", \""];
//    exec = [exec stringByAppendingString:pdfPath];
//    exec = [exec stringByAppendingString:@"\")"];
//
//    //Run the insert
//    result = sqlite3_exec(database, [exec cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL);
//    if (result != SQLITE_OK){
//        if (result == 19) { //Entry already exists
//            exec = @"UPDATE CuesheetAssignment SET CuesheetPath = \"";
//            exec = [exec stringByAppendingString:pdfPath];
//            exec = [exec stringByAppendingString:@"\" WHERE FileName = \""];
//            exec = [exec stringByAppendingString:fileName];
//            exec = [exec stringByAppendingString:@"\""];
//
//            //Run the update!
//            result = sqlite3_exec(database, [exec cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL);
//            if (result != SQLITE_OK) {
//                sqlite3_close(database);
//                return false;
//            }
//        }else {
//            sqlite3_close(database);
//            return false;
//        }
//    }
//
//    sqlite3_close(database);
//    return true;
//}
//
//+ (bool)deleteFromCuesheetAssignment:(NSString *)fileName{
//    sqlite3 *database;
//    int result;
//
//    result = sqlite3_open([[Database getDBPath] cStringUsingEncoding:NSUTF8StringEncoding], &database);
//    if(result != SQLITE_OK){
//        sqlite3_close(database);
//        return false;
//    }
//
//    NSString *exec = @"DELETE FROM CuesheetAssignment WHERE FileName = \"";
//    exec = [exec stringByAppendingString:fileName];
//    exec = [exec stringByAppendingString:@"\""];
//
//    //Run the update!
//    result = sqlite3_exec(database, [exec cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL);
//    if (result != SQLITE_OK) {
//        sqlite3_close(database);
//        return false;
//    }
//
//    sqlite3_close(database);
//    return true;
//}

+ (bool)insertSongIntoHistory:(NSString *)songTitle withArtist:(NSString *)songArtist withPath:(NSString *)songPath{
    sqlite3 *database;
    int result;
    
    result = sqlite3_open([[Database getDBPath] cStringUsingEncoding:NSUTF8StringEncoding], &database);
    if(result != SQLITE_OK){
        sqlite3_close(database);
        return nil;
    }
    
    NSString *exec = @"INSERT INTO SongHistory VALUES(\"";
    
    if (songTitle != nil) {
        exec = [exec stringByAppendingString:songTitle];
    }else {
        exec = [exec stringByAppendingString:@" "];
    }
    
    exec = [exec stringByAppendingString:@"\", \""];
    
    if (songArtist != nil) {
        exec = [exec stringByAppendingString:songArtist];
    }else {
        exec = [exec stringByAppendingString:@" "];
    }
    
    exec = [exec stringByAppendingString:@"\", \""];
    
    if ([songPath lastPathComponent] != nil) {
        exec = [exec stringByAppendingString:[songPath lastPathComponent]];
    }else {
        exec = [exec stringByAppendingString:@" "];
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //Save the date/time infos in UTC
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    
    dateFormatter.dateFormat = @"yyyyMMdd";
    NSString *date = [dateFormatter stringFromDate: [NSDate new]];
    
    dateFormatter.dateFormat = @"hhmmss";
    NSString *time = [dateFormatter stringFromDate: [NSDate new]];
    
    exec = [exec stringByAppendingString:@"\", \""];
    exec = [exec stringByAppendingString:date];
    exec = [exec stringByAppendingString:@"\", \""];
    exec = [exec stringByAppendingString:time];
    exec = [exec stringByAppendingString:@"\")"];
    
    //Run the insert
    result = sqlite3_exec(database, [exec cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL);
    if (result != SQLITE_OK){
        sqlite3_close(database);
        return false;
    }
    
    sqlite3_close(database);
    return true;
}

//+ (NSString *)getAssignedPDF:(NSString *)fileName{
//    NSString *pdfPath = nil;
//    sqlite3 *database;
//    int result;
//    
//    result = sqlite3_open([[Database getDBPath] cStringUsingEncoding:NSUTF8StringEncoding], &database);
//    if(result != SQLITE_OK){
//        sqlite3_close(database);
//        return nil;
//    }
//    
//    NSString *selectStmt = @"SELECT CuesheetPath FROM CuesheetAssignment WHERE FileName = \"";
//    selectStmt = [selectStmt stringByAppendingString:fileName];
//    selectStmt = [selectStmt stringByAppendingString:@"\""];
//    
//    sqlite3_stmt *statement;
//    
//    result = sqlite3_prepare(database, [selectStmt cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, nil);
//    if(result != SQLITE_OK){
//        sqlite3_close(database);
//        return nil;
//    }
//    
//    if (sqlite3_step(statement) == SQLITE_ROW){
//        @try {
//            pdfPath = [NSString stringWithCString:(char *)sqlite3_column_text(statement, 0) encoding:NSUTF8StringEncoding];
//        }
//        @catch (NSException *e){
//            pdfPath = nil;
//        }
//    }else {
//        sqlite3_finalize(statement);
//        sqlite3_close(database);
//        return nil;
//    }
//    
//    sqlite3_finalize(statement);
//    sqlite3_close(database);
//    
//    return pdfPath;
//}

//+ (NSMutableArray *)getPlaylists{
//    sqlite3 *database;
//    int result;
//    NSMutableArray *values = nil;
//
//    result = sqlite3_open([[Database getDBPath] cStringUsingEncoding:NSUTF8StringEncoding], &database);
//    if(result != SQLITE_OK){
//        sqlite3_close(database);
//        return nil;
//    }
//
//    NSString *selectStmt = @"SELECT * FROM Playlist ORDER BY IOrder, Description";
//
//    sqlite3_stmt *statement;
//
//    result = sqlite3_prepare(database, [selectStmt cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, nil);
//    if(result != SQLITE_OK){
//
//        //Something went wrong => Order not available
//        //Add the column
//
//        result = sqlite3_exec(database, "ALTER TABLE Playlist ADD IOrder INT", NULL, NULL, NULL);
//
//        if(result != SQLITE_OK){
//            sqlite3_close(database);
//            return false;
//        }
//
//        selectStmt = @"SELECT * FROM Playlist ORDER BY Description";
//
//        result = sqlite3_prepare(database, [selectStmt cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, nil);
//        if(result != SQLITE_OK){
//            sqlite3_close(database);
//            return nil;
//        }
//
//    }
//
//    values = [[NSMutableArray alloc] init];
//
//    while (sqlite3_step(statement) == SQLITE_ROW){
//        //ID
//        int plID = 0;
//        @try {
//            plID  = [[NSString stringWithCString:(char *)sqlite3_column_text(statement, 0) encoding:NSUTF8StringEncoding] intValue];
//        }
//        @catch (NSException *exception) { }
//
//        //Description
//        NSString *desc = nil;
//        @try {
//            desc = [NSString stringWithCString:(char *)sqlite3_column_text(statement, 1) encoding:NSUTF8StringEncoding];
//        }
//        @catch (NSException *exception) { desc = @""; }
//
//        //ContPlayback
//        bool cp   = false;
//
//        @try {
//            cp = [[NSString stringWithCString:(char *)sqlite3_column_text(statement, 2) encoding:NSUTF8StringEncoding] boolValue];
//        }
//        @catch (NSException *exception) { }
//
//        //Pause
//        int pause  = 0;
//
//        @try{
//            pause = [[NSString stringWithCString:(char *)sqlite3_column_text(statement, 3) encoding:NSUTF8StringEncoding] intValue];
//        }
//        @catch (NSException *exception) { }
//
//        //Order
//        int order  = 0;
//
//        @try {
//            order = [[NSString stringWithCString:(char *)sqlite3_column_text(statement, 4) encoding:NSUTF8StringEncoding] intValue];
//        }
//        @catch (NSException *exception) { }
//
//        Playlist *playlist = [[Playlist alloc] initExistingPlaylist:plID withDesc:desc withContPlayback:cp withPause:pause withOrder:order];
//
//        [values addObject:playlist];
//        [playlist release];
//    }
//
//    sqlite3_finalize(statement);
//    sqlite3_close(database);
//
//    if ([values count] == 0) {
//        [values release];
//        return nil;
//    }else{
//        [values autorelease];
//        return values;
//    }
//}

//+ (NSMutableArray *)getPlaylistSongs:(int)playlistID{
//    sqlite3 *database;
//    int result;
//    NSMutableArray *values = nil;
//
//    if (playlistID < 0) {
//        return nil;
//    }
//
//    result = sqlite3_open([[Database getDBPath] cStringUsingEncoding:NSUTF8StringEncoding], &database);
//    if(result != SQLITE_OK){
//        sqlite3_close(database);
//        return nil;
//    }
//
//    NSString *selectStmt = @"SELECT * FROM PlaylistSong WHERE PID = ";
//    selectStmt = [selectStmt stringByAppendingFormat:@"%d ORDER BY SongOrder",playlistID];
//
//    sqlite3_stmt *statement;
//
//    result = sqlite3_prepare(database, [selectStmt cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, nil);
//    if(result != SQLITE_OK){
//        sqlite3_close(database);
//        return nil;
//    }
//
//    values = [[NSMutableArray alloc] init];
//
//    while (sqlite3_step(statement) == SQLITE_ROW){
//        //ID
//        NSString *title    = nil;
//
//        @try {
//            title = [NSString stringWithCString:(char *)sqlite3_column_text(statement, 2) encoding:NSUTF8StringEncoding];
//        }
//        @catch (NSException *e) { title = @""; }
//
//        //Description
//        NSString *filename = nil;
//
//        @try{
//            filename = [NSString stringWithCString:(char *)sqlite3_column_text(statement, 3) encoding:NSUTF8StringEncoding];
//        }
//        @catch (NSException *e) { filename = @""; }
//
//        //ContPlayback
//        NSString *duration = nil;
//
//        @try {
//            duration = [NSString stringWithCString:(char *)sqlite3_column_text(statement, 4) encoding:NSUTF8StringEncoding];
//        }
//        @catch(NSException *e) { duration = @"0:00"; }
//
//        Song *song = [ClogAmpMacDataBuffer findSong:title withFilename:filename withDuration:duration];
//
//        if (song != nil){
//            [values addObject:song];
//        }
//    }
//
//    sqlite3_finalize(statement);
//    sqlite3_close(database);
//
//    if ([values count] == 0) {
//        [values release];
//        return nil;
//    }else{
//        [values autorelease];
//        return values;
//    }
//}

+ (NSMutableArray *)getSongHistory:(NSDate *)fromDate toDate:(NSDate *)toDate{
    sqlite3 *database;
    int result;
    NSMutableArray *values = nil;
    
    result = sqlite3_open([[Database getDBPath] cStringUsingEncoding:NSUTF8StringEncoding], &database);
    if(result != SQLITE_OK){
        sqlite3_close(database);
        return nil;
    }
    
    NSString *selectStmt = @"SELECT * FROM SongHistory ORDER BY PlayedDate DESC, PlayedTime DESC";
    
    sqlite3_stmt *statement;
    
    result = sqlite3_prepare(database, [selectStmt cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, nil);
    if(result != SQLITE_OK){
        sqlite3_close(database);
        return nil;
    }
    
    values = [[NSMutableArray alloc] init];
    
    while (sqlite3_step(statement) == SQLITE_ROW){
        
        NSString *title  = nil;
        NSString *artist = nil;
        NSString *path   = nil;
        NSString *dateS  = nil;
        NSString *timeS  = nil;
        
        @try {
            
            title = [NSString stringWithCString:(char *)sqlite3_column_text(statement, 0) encoding:NSUTF8StringEncoding];
            
        }
        @catch(NSException *e) { title = @""; }
        
        @try {
            artist = [NSString stringWithCString:(char *)sqlite3_column_text(statement, 1) encoding:NSUTF8StringEncoding];
            
        }
        @catch(NSException *e) { artist = @""; }
        
        @try{
            
            path = [NSString stringWithCString:(char *)sqlite3_column_text(statement, 2) encoding:NSUTF8StringEncoding];
            
        }
        @catch(NSException *e) { path = @""; }
        
        @try{
            dateS  = [NSString stringWithCString:(char *)sqlite3_column_text(statement, 3) encoding:NSUTF8StringEncoding];
            timeS  = [NSString stringWithCString:(char *)sqlite3_column_text(statement, 4) encoding:NSUTF8StringEncoding];
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
            
            //Create a NSDate for UTC
            [dateFormatter setLocale: [[NSLocale alloc] initWithLocaleIdentifier: @"en_US_POSIX"]];
            [timeFormatter setLocale: [[NSLocale alloc] initWithLocaleIdentifier: @"en_US_POSIX"]];
            
            dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
            timeFormatter.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
            
            [dateFormatter setDateFormat:@"yyyyMMdd"];
            [timeFormatter setDateFormat:@"HHmmss"];
            
            NSDate *date = [dateFormatter dateFromString:dateS];
            NSDate *time = [timeFormatter dateFromString:timeS];
            
            //Convert the NSDate objects to local format
            [dateFormatter setLocale:NSLocale.currentLocale];
            [timeFormatter setLocale:NSLocale.currentLocale];
            
            dateFormatter.timeZone = NSTimeZone.localTimeZone;
            timeFormatter.timeZone = NSTimeZone.localTimeZone;
            
            [dateFormatter setLocalizedDateFormatFromTemplate:@"yyyyMMdd"];
            dateS = [dateFormatter stringFromDate:date];
            
            [timeFormatter setLocalizedDateFormatFromTemplate:@"HH:mm:ss"];
            timeS = [timeFormatter stringFromDate:time];

        } @catch(NSException *e) {
            dateS = @"";
            timeS = @"";
        }
        
        SongHistoryItem *shi = [[SongHistoryItem alloc] init];
        
        shi.title  = title;
        shi.artist = artist;
        shi.file   = path;
        shi.date   = [[dateS stringByAppendingString:@", "] stringByAppendingString:timeS];
        
        [values addObject:shi];
    }
    
    sqlite3_finalize(statement);
    sqlite3_close(database);
    
    if ([values count] == 0) {
        return nil;
    }else{
        return values;
    }
}

//+ (int)addPlaylist:(NSString *)desc withContPlayback:(bool)contPlayback{
//    sqlite3 *database;
//    int result;
//
//    result = sqlite3_open([[Database getDBPath] cStringUsingEncoding:NSUTF8StringEncoding], &database);
//    if(result != SQLITE_OK){
//        sqlite3_close(database);
//        return -1;
//    }
//
//    NSString *exec = @"INSERT INTO Playlist (Description, ContPlayback, Pause, IOrder) VALUES(\"";
//    exec = [exec stringByAppendingString:desc];
//    exec = [exec stringByAppendingString:@"\","];
//    exec = [exec stringByAppendingString:[NSString stringWithFormat:@"%d, 0, 99)",contPlayback]];
//
//    //INSERT INTO Playlist (Description, ContPlayback, Pause) VALUES("description", 1, 0, 99)
//
//    //Run the insert
//    result = sqlite3_exec(database, [exec cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL);
//    if (result != SQLITE_OK){
//        sqlite3_close(database);
//        return -1;
//    }
//
//    sqlite3_stmt *statement;
//    exec = @"SELECT MAX(ID) FROM Playlist";
//
//    result = sqlite3_prepare(database, [exec cStringUsingEncoding:NSUTF8StringEncoding], -1, &statement, nil);
//    if(result != SQLITE_OK){
//        sqlite3_close(database);
//        return -1;
//    }
//
//    sqlite3_step(statement);
//
//    NSString *id = nil;
//
//    @try {
//        id = [NSString stringWithCString:(char *)sqlite3_column_text(statement, 0) encoding:NSUTF8StringEncoding];
//    }
//    @catch (NSException *exception) {
//        id = @"0";
//    }
//
//    sqlite3_finalize(statement);
//    sqlite3_close(database);
//    return [id intValue];
//}
//
//+ (bool)updatePlaylist:(int)plID withDesc:(NSString *)desc withContPlayback:(bool)contPlayback withPause:(int)pause withOrder:(int)order{
//    sqlite3 *database;
//    int result;
//
//    result = sqlite3_open([[Database getDBPath] cStringUsingEncoding:NSUTF8StringEncoding], &database);
//    if(result != SQLITE_OK){
//        sqlite3_close(database);
//        return false;
//    }
//
//    NSString *exec = @"UPDATE Playlist SET Description = \"";
//    exec = [exec stringByAppendingString:desc];
//    exec = [exec stringByAppendingString:@"\", ContPlayback = "];
//    exec = [exec stringByAppendingFormat:@"%d",contPlayback];
//    exec = [exec stringByAppendingString:@", Pause = "];
//    exec = [exec stringByAppendingFormat:@"%d",pause];
//    exec = [exec stringByAppendingString:@", IOrder = "];
//    exec = [exec stringByAppendingFormat:@"%d",order];
//    exec = [exec stringByAppendingFormat:@" WHERE ID = %d",plID];
//
//    //Run the update
//    result = sqlite3_exec(database, [exec cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL);
//    if (result != SQLITE_OK){
//        sqlite3_close(database);
//        return false;
//    }
//
//    sqlite3_close(database);
//    return true;
//}
//
//+ (bool)assignSongsToPlaylist:(int)plID withSongs:(NSMutableArray *)songs{
//
//    sqlite3 *database;
//    int order = 0;
//    int result;
//
//    result = sqlite3_open([[Database getDBPath] cStringUsingEncoding:NSUTF8StringEncoding], &database);
//    if(result != SQLITE_OK){
//        sqlite3_close(database);
//        return false;
//    }
//
//    //Delete already assigned songs
//    NSString *deleteExec = [NSString stringWithFormat:@"DELETE FROM PlaylistSong WHERE PID = %d",plID];
//
//    result = sqlite3_exec(database, [deleteExec cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL);
//    if (result != SQLITE_OK){
//        sqlite3_close(database);
//        return false;
//    }
//
//    for(Song *song in songs){
//        order++;
//
//        NSString *exec = @"INSERT INTO PlaylistSong (PID, SongOrder, SongTitle, SongFileName, SongDuration) VALUES(";
//        exec = [exec stringByAppendingFormat:@"%d",plID];
//        exec = [exec stringByAppendingFormat:@", %d, \"",order];
//        exec = [exec stringByAppendingString:[song title]];
//        exec = [exec stringByAppendingString:@"\", \""];
//        exec = [exec stringByAppendingString:[[song path] lastPathComponent]];
//        exec = [exec stringByAppendingString:@"\", \""];
//        exec = [exec stringByAppendingString:[song duration]];
//        exec = [exec stringByAppendingString:@"\")"];
//
//        //Run the update
//        result = sqlite3_exec(database, [exec cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL);
//        if (result != SQLITE_OK){
//            sqlite3_close(database);
//            return false;
//        }
//    }
//
//    sqlite3_close(database);
//    return true;
//}
//
//+ (bool)deletePlaylist:(int)plID{
//
//    sqlite3 *database;
//    int result;
//
//    result = sqlite3_open([[Database getDBPath] cStringUsingEncoding:NSUTF8StringEncoding], &database);
//    if(result != SQLITE_OK){
//        sqlite3_close(database);
//        return false;
//    }
//
//    //Delete PlaylistSongs
//    NSString *deleteExec = [NSString stringWithFormat:@"DELETE FROM PlaylistSong WHERE PID = %d",plID];
//
//    result = sqlite3_exec(database, [deleteExec cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL);
//    if (result != SQLITE_OK){
//        sqlite3_close(database);
//        return false;
//    }
//
//    //Delete Playlist
//    deleteExec = [NSString stringWithFormat:@"DELETE FROM Playlist WHERE ID = %d",plID];
//
//    result = sqlite3_exec(database, [deleteExec cStringUsingEncoding:NSUTF8StringEncoding], NULL, NULL, NULL);
//    if (result != SQLITE_OK){
//        sqlite3_close(database);
//        return false;
//    }
//
//    return true;
//}

@end
