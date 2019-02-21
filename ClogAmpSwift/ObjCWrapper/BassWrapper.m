//
//  BassWrapper.m
//  ClogAmpSwift
//
//  Created by Roessel, Pascal on 15.02.19.
//  Copyright © 2019 Pascal Roessel. All rights reserved.
//

#import "BassWrapper.h"
#import "bass.h"
#import "bass_fx.h"

@implementation BassWrapper

+(float)determineBPM:(NSString *)path length:(int)seconds{

    // Initialize default device.
    if (!BASS_Init(-1, 44100, 0, NULL, NULL)) {
        //Failes on the 2nd ... attempt, no worries
        //NSLog(@"Can't initialize device");
    }
    
    HSTREAM  bpmStream = BASS_StreamCreateFile(FALSE, [path UTF8String], 0, 0, BASS_STREAM_PRESCAN|BASS_SAMPLE_FLOAT|BASS_STREAM_DECODE);
    
    float BpmValue= BASS_FX_BPM_DecodeGet(
                                          bpmStream,
                                          0.00,
                                          seconds,
                                          MAKELONG(45,256),
                                          BASS_FX_FREESOURCE,
                                          NULL);

    return BpmValue;
}

@end
