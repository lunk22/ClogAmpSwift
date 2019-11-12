#import "Id3Wrapper.h"
#import "id3/tag.h"
#import "id3/misc_support.h"

@implementation Id3Wrapper

@synthesize path;

- (NSMutableDictionary *) readBasicInfo {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    ID3_Tag *id3Tag = new ID3_Tag([self.path cStringUsingEncoding:NSUTF8StringEncoding]);
    ID3_Frame *frame = nil;
    
    //Title
    char *title = ID3_GetTitle(id3Tag);
    
    if(title != nil){
        [dict setValue: [NSString stringWithUTF8String:title] forKey:@"title"];
    }
    
    //Artist
    char *artist = ID3_GetArtist(id3Tag);
    
    if(artist != nil){
        [dict setValue: [NSString stringWithUTF8String:artist] forKey:@"artist"];
    }
    
    //Duration
    frame = id3Tag->Find(ID3FID_SONGLEN);
    const Mp3_Headerinfo* mp3Info = id3Tag->GetMp3HeaderInfo();
    if(mp3Info != NULL) {
        [dict setValue: [NSNumber numberWithInt:mp3Info->time] forKey:@"duration"];
    }
    
    //CloggingLevel
    frame = nil;
    frame = id3Tag->Find(ID3FID_USERTEXT, ID3FN_DESCRIPTION, [@"CloggingLevel" cStringUsingEncoding:NSUTF8StringEncoding]);
    if (frame){
        char *usertext = ID3_GetString(frame, ID3FN_TEXT);
        [dict setValue: [NSString stringWithUTF8String:usertext] forKey:@"cloggingLevel"];
    }
    
    //LastTempo
    frame = nil;
    frame = id3Tag->Find(ID3FID_USERTEXT, ID3FN_DESCRIPTION, [@"LastTempo" cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if (frame){
        char *usertext = ID3_GetString(frame, ID3FN_TEXT);
        [dict setValue: [NSString stringWithUTF8String:usertext] forKey:@"lastTempo"];
    }
    
    //BPM
    frame = nil;
    frame = id3Tag->Find(ID3FID_BPM);
    
    if (frame != NULL) {
        char *sBPM = ID3_GetString(frame, ID3FN_TEXT);
        
        if (sBPM != nil) {
            @try {
                [dict setValue: [NSNumber numberWithInt:[[NSString stringWithCString:sBPM encoding:NSUTF8StringEncoding] intValue]] forKey:@"bpm"];
            }@catch (NSException *e) {}
        }
    }
    
    //Has Positions
    size_t dataSize;
    const unsigned char *positionsUChar;
    
    ID3_Frame *found = ID3_GetSyncLyrics(id3Tag, "eng", "ClogChoreoParts", positionsUChar, dataSize);
    
    bool isEmpty;
    
    //        isEmpty = [@"" isEqualToString:[NSString stringWithUTF8String:(char *)positionsUChar]];
    char *testChar = (char *)positionsUChar;
    NSUInteger testLength = strlen(testChar);
    if ((int)testLength > 0) {
        isEmpty = false;
    }else{
        isEmpty = true;
    }
    
    if (found != nil && (dataSize != 0 || !isEmpty)){
        [dict setValue: [NSNumber numberWithBool:true] forKey:@"hasPositions"];
    }else{
        [dict setValue: [NSNumber numberWithBool:false] forKey:@"hasPositions"];
    }
    
    return dict;
}

- (NSString *) readUserText:(const char*)text {
    ID3_Tag *id3Tag  = new ID3_Tag([self.path cStringUsingEncoding:NSUTF8StringEncoding]);
    ID3_Frame *frame = nil;
    
    if (text){
        frame = id3Tag->Find(ID3FID_USERTEXT, ID3FN_DESCRIPTION, text);
    }else{
        frame = id3Tag->Find(ID3FID_USERTEXT);
    }
    
    NSString *returnText = @"";
    
    if (frame){
        char *usertext = ID3_GetString(frame, ID3FN_TEXT);
        returnText = [NSString stringWithUTF8String:usertext];
    }
    
    return returnText;
}

- (bool) hasPositions {
    size_t dataSize;
    const unsigned char *positionsUChar;
    
    ID3_Tag *id3Tag  = new ID3_Tag([self.path cStringUsingEncoding:NSUTF8StringEncoding]);
    ID3_Frame *found = ID3_GetSyncLyrics(id3Tag, "eng", "ClogChoreoParts", positionsUChar, dataSize);
    
    bool isEmpty;
    
    //        isEmpty = [@"" isEqualToString:[NSString stringWithUTF8String:(char *)positionsUChar]];
    char *testChar = (char *)positionsUChar;
    NSUInteger testLength = strlen(testChar);
    if ((int)testLength > 0) {
        isEmpty = false;
    }else{
        isEmpty = true;
    }
    
    if (found != nil && (dataSize != 0 || !isEmpty)){
        return true;
    }
    
    return false;
}

- (NSString *) loadPositions {
    NSMutableString *returnString = [NSMutableString new];
    
    size_t dataSize;
    const uchar *positionsUChar;
    
    ID3_Tag *id3Tag  = new ID3_Tag([self.path cStringUsingEncoding:NSUTF8StringEncoding]);
    ID3_Frame *found = ID3_GetSyncLyrics(id3Tag, "eng", "ClogChoreoParts", positionsUChar, dataSize);
    
    bool isEmpty;

//        isEmpty = [@"" isEqualToString:[NSString stringWithUTF8String:(char *)positionsUChar]];
    char *testChar = (char *)positionsUChar;
    NSUInteger testLength = strlen(testChar);
    if ((int)testLength > 0) {
        isEmpty = false;
    }else{
        isEmpty = true;
    }
    
    if (found != nil && (dataSize != 0 || !isEmpty)){
        
        // There is a whole bunch of chars
        // We have:
        // Name of the position\t
        // Jump to\t
        // Comment\0
        // Milliseconds (32 bit)
        
        int count = 0;
        char *positionsChar;
        
        NSUInteger length = 0;
        
        NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@"\t"];
        
        NSRange range;
        
        NSString *name;
        NSString *comment;
        NSString *jumpTo;
        
        while (count < dataSize){
            comment = @"";
            jumpTo = @"";
            
            positionsChar = (char *)positionsUChar;
            length = strlen(positionsChar) + 1; //Because of the '\0'
            
            NSString *posiLine = [NSString stringWithCString:positionsChar encoding:NSISOLatin1StringEncoding];
            
            positionsUChar += length;
            count += length;
            
            if(posiLine != nil){
                //Look for tabs (\t) in the line
                range = [posiLine rangeOfCharacterFromSet:charSet];
                if (range.location != NSNotFound && range.location < length) {
                    //Tab has been found
                    NSArray *array = [posiLine componentsSeparatedByString:@ "\t"];
                    
                    name = [array objectAtIndex:0];
                    
                    if ([array count] == 2) { //Name + Comment
                        comment = [array objectAtIndex:1];
                    }else if ([array count] == 3) { //Name + Jump To + Comment
                        jumpTo  = [array objectAtIndex:1];
                        comment = [array objectAtIndex:2];
                    }
                }else{
                    //No tabs have been found => only the name?
                    name = posiLine;
                }
                
                unsigned int ms = 0;
                for (int i = 0; i < 4; ++i) {
                    ms <<= 8;
                    ms += positionsUChar[i];
                }
                
                if([returnString length] > 0){
                    [returnString appendString:@"$LS"]; //$LS = Line Separator
                }
                
                [returnString appendFormat:@"%@$CS%@$CS%@$CS%u", name ? name : @"", comment ? comment : @"", jumpTo ? jumpTo : @"", ms]; //$CS = Cell Separator
            }
            
            positionsUChar += 4;
            count += 4;

        }

    }
    
    return returnString;
    
}

- (void) saveTitle:(NSString *)sValue {
    ID3_Tag *id3Tag = new ID3_Tag([self.path cStringUsingEncoding:NSUTF8StringEncoding]);
    ID3_AddTitle(id3Tag, [sValue cStringUsingEncoding:NSUTF8StringEncoding], true);
    
    id3Tag->Update();
}

- (void) saveArtist:(NSString *)sValue {
    ID3_Tag *id3Tag = new ID3_Tag([self.path cStringUsingEncoding:NSUTF8StringEncoding]);
    ID3_AddArtist(id3Tag, [sValue cStringUsingEncoding:NSUTF8StringEncoding], true);
    
    id3Tag->Update();
}

- (void) saveUserText:(NSString *)text sValue:(NSString *)sValue {
    ID3_Tag *id3Tag  = new ID3_Tag([self.path cStringUsingEncoding:NSUTF8StringEncoding]);
    ID3_Frame *frame = nil;
    
    bool bAdd = NO;
    
    // See if there is already a comment with this description
    frame = id3Tag->Find(ID3FID_USERTEXT, ID3FN_DESCRIPTION, [text cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if(frame == nil){
        frame = new ID3_Frame(ID3FID_USERTEXT);
        bAdd = YES;
    }
    
    // IMPORTANT:
    // Always specify the text encoding, for every field
    frame->Field(ID3FN_TEXTENC).Set(ID3TE_ISO8859_1); //ID3TE_ISO8859_1    ID3TE_UTF8
    frame->Field(ID3FN_DESCRIPTION).SetEncoding(ID3TE_ISO8859_1);
    frame->Field(ID3FN_DESCRIPTION).Set([text cStringUsingEncoding:NSISOLatin1StringEncoding]);
    frame->Field(ID3FN_TEXT).SetEncoding(ID3TE_ISO8859_1);
    frame->Field(ID3FN_TEXT).Set([sValue cStringUsingEncoding:NSISOLatin1StringEncoding]);
    
    if(bAdd){
        id3Tag->AttachFrame(frame);
    }
    
    id3Tag->Update();
}

- (void) removeAllBpms {
    ID3_Tag *id3Tag  = new ID3_Tag([self.path cStringUsingEncoding:NSUTF8StringEncoding]);
    ID3_Frame *frame = NULL;
    int num_removed = 0;
    
    if (NULL == id3Tag)
    {
        return;
    }
    
    while ((frame = id3Tag->Find(ID3FID_BPM)))
    {
        frame = id3Tag->RemoveFrame(frame);
        delete frame;
        num_removed++;
    }
    
    id3Tag->Update();
}

- (void) saveBPM:(int)bpm {
    ID3_Tag *id3Tag  = new ID3_Tag([self.path cStringUsingEncoding:NSUTF8StringEncoding]);
    ID3_Frame* frame;

    if (bpm < 0){
        bpm = 0;
    }
    
    const char *charBPM = [[NSString stringWithFormat:@"%i",bpm] UTF8String];

//    [Tools removeBPMs:id3Tag];

    frame = new ID3_Frame(ID3FID_BPM);

    if (frame){
        frame->Field(ID3FN_TEXT).SetEncoding(ID3TE_ISO8859_1);
        frame->Field(ID3FN_TEXT) = charBPM;
        id3Tag->AttachFrame(frame);
    }
    
    id3Tag->Update();
}

- (void) savePositions:(NSString *)positionString {
    ID3_Tag *id3Tag  = new ID3_Tag([self.path cStringUsingEncoding:NSUTF8StringEncoding]);
    
    unsigned char buf[4096], *ptr = buf;
    
    NSString *temp    = nil;
    NSString *comment = nil;
    
    int len = 0;
    
    if(![positionString isEqual: @""]){

        NSArray *positionLine = [positionString componentsSeparatedByString:@"$LS"];
        
        for (unsigned int i = 0; i < [positionLine count]; i++) {
            NSArray *position = [[positionLine objectAtIndex:i] componentsSeparatedByString:@"$CS"];
            
            temp = [position objectAtIndex:0]; //Index 0 = Name
            if (temp == nil) {
                temp = @"";
            }
            
            comment = [position objectAtIndex:1]; //Index 1 = Description
            if (comment == nil) {
                comment = @"";
            }
            
            temp = [temp stringByAppendingString:@"\t"];
            temp = [temp stringByAppendingString:comment];
            
            strcpy((char *)ptr, [temp cStringUsingEncoding:NSISOLatin1StringEncoding]);
            NSUInteger length = [temp length] +1;
            
            len += length;
            ptr += length;
            
            //Index 2 = Jump To
            // tbd...
            
            // add the ms (32bit number)
            int ms = [[position objectAtIndex:3] intValue]; //Index 3 = Time in ms
            
            for (int j = 0; j < 4; j++) {
                unsigned char temp = (ms & 0xff000000) >> 24;
                ptr[j] = temp; // Write leftmost byte
                ms <<= 8;      // and make the one to its right leftmost
            }
            
            len += 4;
            ptr += 4;
        }
   
    }
    
    //Save info
    unsigned char charRep[len];
    
    memcpy((char *)charRep, (char *)buf, len);
    
    ID3_AddSyncLyrics(id3Tag, charRep, len, ID3TSF_MS, "ClogChoreoParts", "eng", ID3CT_MOVEMENT, true);
    
    id3Tag->Update();
}

- (id)init:(NSString*)path {
    self = [super init];
    if (self) {
        self.path = path;
    }
    
    return self;
}

@end
