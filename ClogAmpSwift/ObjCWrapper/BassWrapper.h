//
//  BassWrapper.h
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 15.02.19.
//

#ifndef BassWrapper_h
#define BassWrapper_h

#import <Foundation/Foundation.h>

@interface BassWrapper : NSObject

+(float)determineBPM:(NSString *)path length:(int)seconds sampleRate:(int)sampleRate;

@end

#endif /* BassWrapper_h */
