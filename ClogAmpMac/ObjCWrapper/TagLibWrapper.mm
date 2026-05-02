#import "TagLibWrapper.h"

#include <taglib/mpeg/mpegfile.h>
#include <taglib/mpeg/id3v2/id3v2tag.h>
#include <taglib/mpeg/id3v2/frames/textidentificationframe.h>
#include <taglib/mpeg/id3v2/frames/synchronizedlyricsframe.h>

// MARK: - Helpers

static NSString *nsStr(const TagLib::String &s) {
    const char *c = s.toCString(true);
    return c ? ([NSString stringWithUTF8String:c] ?: @"") : @"";
}

static TagLib::String tlStr(NSString *s) {
    return TagLib::String(s.UTF8String ?: "", TagLib::String::UTF8);
}

// Position string format (ClogAmp): "name$CScomment$CSjumpTo$CSms" entries separated by "$LS"
// SYLT text per entry: "name\tcomment", timestamp: milliseconds (uint)

static NSString *parseSYLTEntries(const TagLib::ID3v2::SynchronizedLyricsFrame::SynchedTextList &entries) {
    NSMutableString *result = [NSMutableString string];
    for (const auto &entry : entries) {
        if (result.length > 0) [result appendString:@"$LS"];
        NSString *text = nsStr(entry.text);
        NSArray<NSString *> *parts = [text componentsSeparatedByString:@"\t"];
        NSString *name    = parts.count > 0 ? parts[0] : @"";
        NSString *comment = parts.count > 1 ? parts[1] : @"";
        [result appendFormat:@"%@$CS%@$CS$CS%u", name, comment, entry.time];
    }
    return result;
}

static TagLib::ID3v2::SynchronizedLyricsFrame::SynchedTextList buildSYLTEntries(NSString *positionString) {
    TagLib::ID3v2::SynchronizedLyricsFrame::SynchedTextList entries;
    if (!positionString.length) return entries;
    for (NSString *line in [positionString componentsSeparatedByString:@"$LS"]) {
        NSArray<NSString *> *cells = [line componentsSeparatedByString:@"$CS"];
        if (cells.count < 4) continue;
        NSString *name    = cells[0];
        NSString *comment = cells[1];
        // cells[2] is jumpTo — not stored, matching ID3TagManager behaviour
        unsigned int ms = (unsigned int)[cells[3] integerValue];
        NSString *combined = [NSString stringWithFormat:@"%@\t%@", name, comment];
        entries.append({ms, tlStr(combined)});
    }
    return entries;
}

static void removeSYLTByDescription(TagLib::ID3v2::Tag *tag, NSString *description) {
    TagLib::List<TagLib::ID3v2::Frame *> toRemove;
    for (auto *frame : tag->frameList("SYLT")) {
        auto *sylt = dynamic_cast<TagLib::ID3v2::SynchronizedLyricsFrame *>(frame);
        if (sylt && [nsStr(sylt->description()) isEqualToString:description])
            toRemove.append(frame);
    }
    for (auto *frame : toRemove) tag->removeFrame(frame);
}

static void removeTXXXByDescription(TagLib::ID3v2::Tag *tag, NSString *description) {
    TagLib::List<TagLib::ID3v2::Frame *> toRemove;
    for (auto *frame : tag->frameList("TXXX")) {
        auto *txxx = dynamic_cast<TagLib::ID3v2::UserTextIdentificationFrame *>(frame);
        if (txxx && [nsStr(txxx->description()) isEqualToString:description])
            toRemove.append(frame);
    }
    for (auto *frame : toRemove) tag->removeFrame(frame);
}

// MARK: - TagLibWrapper

@implementation TagLibWrapper {
    NSString *_path;
}

- (nullable instancetype)initWithPath:(NSString *)path {
    if (!path.length) return nil;
    if (!(self = [super init])) return nil;
    _path = path;
    return self;
}

- (nullable NSDictionary<NSString *, id> *)readBasicInfo {
    TagLib::MPEG::File file(_path.fileSystemRepresentation);
    if (!file.isValid()) return nil;

    NSMutableDictionary *result = [@{ @"duration": @(0), @"hasPositions": @(NO) } mutableCopy];

    if (auto *props = file.audioProperties())
        result[@"duration"] = @(props->lengthInSeconds());

    auto *tag = file.ID3v2Tag();
    if (!tag) return result;

    auto readText = [&](const char *frameID) -> NSString * {
        const auto &list = tag->frameList(frameID);
        return list.isEmpty() ? @"" : nsStr(list.front()->toString());
    };

    NSString *title = readText("TIT2");
    if (title.length) result[@"title"] = title;

    NSString *artist = readText("TPE1");
    if (artist.length) result[@"artist"] = artist;

    int tlenMs = readText("TLEN").intValue;
    if (tlenMs > 0) result[@"duration"] = @(tlenMs / 1000);

    result[@"bpm"] = @(readText("TBPM").intValue);

    for (auto *frame : tag->frameList("TXXX")) {
        auto *txxx = dynamic_cast<TagLib::ID3v2::UserTextIdentificationFrame *>(frame);
        if (!txxx) continue;
        NSString *desc = nsStr(txxx->description());
        auto fields = txxx->fieldList();
        NSString *text = fields.size() >= 2 ? nsStr(fields[1]) : @"";
        if ([desc isEqualToString:@"CloggingLevel"])          result[@"cloggingLevel"] = text;
        else if ([desc isEqualToString:@"LastTempo"])         result[@"lastTempo"] = text;
        else if ([desc isEqualToString:@"CloggingBeatsWait"]) result[@"waitBeats"] = @(text.intValue);
    }

    for (auto *frame : tag->frameList("SYLT")) {
        auto *sylt = dynamic_cast<TagLib::ID3v2::SynchronizedLyricsFrame *>(frame);
        if (!sylt) continue;
        if ([nsStr(sylt->description()) isEqualToString:@"ClogChoreoParts"])
            result[@"hasPositions"] = @(!sylt->synchedText().isEmpty());
    }

    return result;
}

- (NSString *)readUserText:(NSString *)description {
    TagLib::MPEG::File file(_path.fileSystemRepresentation);
    if (!file.isValid()) return @"";
    auto *tag = file.ID3v2Tag();
    if (!tag) return @"";

    for (auto *frame : tag->frameList("TXXX")) {
        auto *txxx = dynamic_cast<TagLib::ID3v2::UserTextIdentificationFrame *>(frame);
        if (!txxx) continue;
        if ([nsStr(txxx->description()) isEqualToString:description]) {
            auto fields = txxx->fieldList();
            return fields.size() >= 2 ? nsStr(fields[1]) : @"";
        }
    }
    return @"";
}

- (NSString *)loadPositions {
    TagLib::MPEG::File file(_path.fileSystemRepresentation);
    if (!file.isValid()) return @"";
    auto *tag = file.ID3v2Tag();
    if (!tag) return @"";

    for (auto *frame : tag->frameList("SYLT")) {
        auto *sylt = dynamic_cast<TagLib::ID3v2::SynchronizedLyricsFrame *>(frame);
        if (!sylt) continue;
        if ([nsStr(sylt->description()) isEqualToString:@"ClogChoreoParts"])
            return parseSYLTEntries(sylt->synchedText());
    }
    return @"";
}

// MARK: - Writes

- (void)saveTitle:(NSString *)value {
    TagLib::MPEG::File file(_path.fileSystemRepresentation);
    if (!file.isValid()) return;
    auto *tag = file.ID3v2Tag(true);
    tag->removeFrames("TIT2");
    auto *frame = new TagLib::ID3v2::TextIdentificationFrame("TIT2", TagLib::String::UTF8);
    frame->setText(tlStr(value));
    tag->addFrame(frame);
    file.save();
}

- (void)saveArtist:(NSString *)value {
    TagLib::MPEG::File file(_path.fileSystemRepresentation);
    if (!file.isValid()) return;
    auto *tag = file.ID3v2Tag(true);
    tag->removeFrames("TPE1");
    auto *frame = new TagLib::ID3v2::TextIdentificationFrame("TPE1", TagLib::String::UTF8);
    frame->setText(tlStr(value));
    tag->addFrame(frame);
    file.save();
}

- (void)saveUserText:(NSString *)description value:(NSString *)value {
    TagLib::MPEG::File file(_path.fileSystemRepresentation);
    if (!file.isValid()) return;
    auto *tag = file.ID3v2Tag(true);
    removeTXXXByDescription(tag, description);
    auto *frame = new TagLib::ID3v2::UserTextIdentificationFrame(TagLib::String::UTF8);
    frame->setDescription(tlStr(description));
    frame->setText(tlStr(value));
    tag->addFrame(frame);
    file.save();
}

- (void)removeAllBpms {
    TagLib::MPEG::File file(_path.fileSystemRepresentation);
    if (!file.isValid()) return;
    auto *tag = file.ID3v2Tag(true);
    tag->removeFrames("TBPM");
    file.save();
}

- (void)saveBPM:(int32_t)bpm {
    TagLib::MPEG::File file(_path.fileSystemRepresentation);
    if (!file.isValid()) return;
    auto *tag = file.ID3v2Tag(true);
    tag->removeFrames("TBPM");
    auto *frame = new TagLib::ID3v2::TextIdentificationFrame("TBPM", TagLib::String::UTF8);
    frame->setText(tlStr([NSString stringWithFormat:@"%d", bpm]));
    tag->addFrame(frame);
    file.save();
}

- (void)savePositions:(NSString *)positionString {
    TagLib::MPEG::File file(_path.fileSystemRepresentation);
    if (!file.isValid()) return;
    auto *tag = file.ID3v2Tag(true);
    removeSYLTByDescription(tag, @"ClogChoreoParts");
    auto *frame = new TagLib::ID3v2::SynchronizedLyricsFrame(TagLib::String::UTF8);
    frame->setLanguage("eng");
    frame->setTimestampFormat(TagLib::ID3v2::SynchronizedLyricsFrame::AbsoluteMilliseconds);
    frame->setType(TagLib::ID3v2::SynchronizedLyricsFrame::Movement);
    frame->setDescription(tlStr(@"ClogChoreoParts"));
    frame->setSynchedText(buildSYLTEntries(positionString));
    tag->addFrame(frame);
    file.save();
}

@end
