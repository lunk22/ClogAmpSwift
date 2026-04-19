#ifndef Id3Wrapper_h
#define Id3Wrapper_h

#import <Foundation/Foundation.h>

@interface Id3Wrapper : NSObject {
    NSString *path;
}

@property (nonatomic, retain) NSString *path;

- (NSMutableDictionary *) readBasicInfo;
- (NSString *) readUserText:(const char*)text;
- (bool) hasPositions;
- (NSString *) loadPositions;

- (void) saveTitle:(NSString *)sValue;
- (void) saveArtist:(NSString *)sValue;
- (void) saveUserText:(NSString *)text sValue:(NSString *)sValue;
- (void) savePositions:(NSString *)positionString;

- (id)init:(NSString*)path;

@end

#endif /* Id3Wrapper_h */
