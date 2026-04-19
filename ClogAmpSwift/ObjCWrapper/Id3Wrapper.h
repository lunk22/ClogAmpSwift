#import <Foundation/Foundation.h>
//#import "id3.h"
//#import "id3/tag.h"
//#import "id3/misc_support.h"

@interface Id3Wrapper : NSObject {
    NSString *path;
}

@property (nonatomic, retain) NSString *path;

- (NSString *) readArtist;
- (NSString *) readTitle;
- (NSString *) readUserText:(const char*)text;
- (bool) hasPositions;
- (NSString *) loadPositions;
    
- (id)init:(NSString*)path;

@end
