#import "Id3Wrapper.h"
#import "id3/tag.h"
#import "id3/misc_support.h"

@implementation Id3Wrapper

@synthesize path;

- (NSString *) readArtist {
    ID3_Tag *id3Tag = new ID3_Tag([self.path cStringUsingEncoding:NSUTF8StringEncoding]);
    char *artist = ID3_GetArtist(id3Tag);
    
    if(artist != nil){
        return [NSString stringWithUTF8String:artist];
    }else{
        return @"";
    }
}

- (NSString *) readTitle {
    ID3_Tag *id3Tag = new ID3_Tag([self.path cStringUsingEncoding:NSUTF8StringEncoding]);
    char *title = ID3_GetTitle(id3Tag);
    
    if(title != nil){
        return [NSString stringWithUTF8String:title];
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
        
//        positionsUChar += 4;
//        count += 4;
        
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
                
                //                NSLog(@"Name: %@ - Comment: %@ - JumpTo: %@ - Time: %u", name, comment, jumpTo, ms);
                
                if([returnString length] > 0){
                    [returnString appendString:@"$LS"]; //$LS = Line Separator
                }
                
                [returnString appendFormat:@"%@$CS%@$CS%@$CS%u", name ? name : @"", comment ? comment : @"", jumpTo ? jumpTo : @"", ms]; //$CS = Cell Separator
            }
            
            positionsUChar += 4;
            count += 4;

        }

    }
    
    id3Tag->Clear();
    
    delete id3Tag;
    
    return returnString;
    
}

- (id)init:(NSString*)path {
    self = [super init];
    if (self) {
        self.path   = path;
    }
    
    return self;
}

@end
