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
        NSLog(@"Can't initialize device");

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
    
//old #2
//    BASS_SetConfig(BASS_CONFIG_IOS_MIXAUDIO, 0); // Disable mixing. To be called before BASS_Init.
//
//    if (HIWORD(BASS_GetVersion()) != BASSVERSION) {
//        NSLog(@"An incorrect version of BASS was loaded");
//    }
//
//    // Initialize default device.
//    if (!BASS_Init(-1, 44100, 0, NULL, NULL)) {
//        NSLog(@"Can't initialize device");
//
//    }
//
//    NSString *respath = path;
//
//    DWORD chan1;
//    if(!(chan1=BASS_StreamCreateFile(FALSE, [respath UTF8String], 0, 0, BASS_SAMPLE_LOOP))) {
//        NSLog(@"Can't load stream!");
//
//    }
//
//    HSTREAM mainStream = BASS_StreamCreateFile(FALSE, [respath cStringUsingEncoding:NSUTF8StringEncoding], 0, 0, BASS_SAMPLE_FLOAT|BASS_STREAM_PRESCAN|BASS_STREAM_DECODE);
//
//    float playBackDuration=BASS_ChannelBytes2Seconds(mainStream, BASS_ChannelGetLength(mainStream, BASS_POS_BYTE));
//    NSLog(@"Play back duration is %f",playBackDuration);
//    HSTREAM bpmStream=BASS_StreamCreateFile(FALSE, [respath UTF8String], 0, 0, BASS_STREAM_PRESCAN|BASS_SAMPLE_FLOAT|BASS_STREAM_DECODE);
//    //BASS_ChannelPlay(bpmStream,FALSE);
//    float BpmValue = BASS_FX_BPM_DecodeGet(bpmStream,0.0,
//                                    playBackDuration,
//                                    MAKELONG(45,256),
//                                    BASS_FX_BPM_MULT2,
//                                    NULL,
//                                    NULL);
//    NSLog(@"BPM is %f", BpmValue);
//    return BpmValue;
    
//old #1
//    HSTREAM bpmHandle;
//    float bpmDecode;
//
//    //    Init BASS
//    bool noErr = BASS_Init(0, 44100, BASS_DEVICE_NOSPEAKER, 0, NULL);
//
//    if (!noErr) {
//        int x = BASS_ErrorGetCode();
//        NSLog(@"BASS Error Code: %i", x);
//        //BASS_ERROR_FORMAT
//        return 0.0f;
//    }
//
//    //    create decode stream
//    bpmHandle = BASS_StreamCreateFile(FALSE, [path UTF8String], 0, 0, BASS_STREAM_DECODE);
//
//    //    get bpm value from position 0 to position X (in seconds)
//    bpmDecode = BASS_FX_BPM_DecodeGet(bpmHandle, 0, seconds, 0, BASS_FX_FREESOURCE, NULL, NULL);
//
//    //    free decode bpm and stream handles
//    BASS_FX_BPM_Free(bpmHandle);
//
//    BASS_Free();
//
//    return bpmDecode;
}

@end
