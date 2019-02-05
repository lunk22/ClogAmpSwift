#import "Id3Wrapper.h"
#import "id3/tag.h"
#import "id3/misc_support.h"

@implementation Id3Wrapper

@synthesize path;

- (NSString *) readTitle {
    ID3_Tag *id3Tag = new ID3_Tag([self.path cStringUsingEncoding:NSUTF8StringEncoding]);
    char *title = ID3_GetTitle(id3Tag);
    
    id3Tag->Clear();
    delete id3Tag;
    
    if(title != nil){
        return [NSString stringWithUTF8String:title];
    }else{
        return @"";
    }
}

- (NSString *) readArtist {
    ID3_Tag *id3Tag = new ID3_Tag([self.path cStringUsingEncoding:NSUTF8StringEncoding]);
    char *artist = ID3_GetArtist(id3Tag);
    
    if(artist != nil){
        return [NSString stringWithUTF8String:artist];
    }else{
        return @"";
    }
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
    ID3_Frame *found = ID3_GetSyncLyrics(id3Tag, NULL, "ClogChoreoParts", positionsUChar, dataSize);
    
    if (found != nil && dataSize != 0){
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
    
    if (found != nil && dataSize != 0){
        
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
            name = @"";
            comment = @"";
            jumpTo = @"";
            
//            NSLog(@"-----");
//            NSData *dataData = [NSData dataWithBytes:positionsUChar length:sizeof(positionsUChar)];
//            NSLog(@"data = %@", dataData);
            
            positionsChar = (char *)positionsUChar;
            length = strlen(positionsChar) + 1; //Because of the '\0'
            
            NSString *posiLine = [NSString stringWithUTF8String:positionsChar];
            
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
    frame->Field(ID3FN_TEXTENC).Set(ID3TE_UTF8); //ID3TE_ISO8859_1    ID3TE_UTF8
    frame->Field(ID3FN_DESCRIPTION).SetEncoding(ID3TE_UTF8); //ID3TE_ISO8859_1
    frame->Field(ID3FN_DESCRIPTION).Set([sValue cStringUsingEncoding:NSUTF8StringEncoding]);
    frame->Field(ID3FN_TEXT).SetEncoding(ID3TE_UTF8); //ID3TE_ISO8859_1
    frame->Field(ID3FN_TEXT).Set([text cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if(bAdd){
        id3Tag->AttachFrame(frame);
    }
    
    id3Tag->Update();
}

- (id)init:(NSString*)path {
    self = [super init];
    if (self) {
        self.path   = path;
    }
    
    return self;
}

@end
