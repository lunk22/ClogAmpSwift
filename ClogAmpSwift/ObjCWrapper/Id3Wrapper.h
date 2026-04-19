#import <Foundation/Foundation.h>
//#import "id3.h"
//#import "id3/tag.h"
//#import "id3/misc_support.h"

@interface Id3Wrapper : NSObject {
    NSString *path;
}

@property (nonatomic, retain) NSString *path;

- (NSString *) readTitle;
- (NSString *) readArtist;
- (NSString *) readUserText:(const char*)text;
- (bool) hasPositions;
- (NSString *) loadPositions;

- (void) saveTitle:(NSString *)sValue;
- (void) saveArtist:(NSString *)sValue;
- (void) saveUserText:(NSString *)text sValue:(NSString *)sValue;
- (void) savePositions:(NSString *)text sValue:(NSString *)sValue;

- (id)init:(NSString*)path;

@end
