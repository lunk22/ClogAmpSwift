#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TagLibWrapper : NSObject

- (nullable instancetype)initWithPath:(NSString *)path;

- (nullable NSDictionary<NSString *, id> *)readBasicInfo;
- (NSString *)readUserText:(NSString *)description;
- (NSString *)loadPositions;

- (void)saveTitle:(NSString *)value;
- (void)saveArtist:(NSString *)value;
- (void)saveUserText:(NSString *)description value:(NSString *)value;
- (void)removeAllBpms;
- (void)saveBPM:(int32_t)bpm;
- (void)savePositions:(NSString *)positionString;

@end

NS_ASSUME_NONNULL_END
