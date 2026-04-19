# ClogAmpMac
ClogAmp from Mac (Swift) 

<img src="https://raw.githubusercontent.com/lunk22/ClogAmpSwift/master/ClogAmpSwift/Assets.xcassets/Icon.imageset/256-mac.png" width="50" height="50">

Built for Clogging Enthusiasts to play music, manipulate speed, edit positions, ...

## Features
- Set playback speed (+ / -)
- Create (A) and maintain positions (with comment column for storing the cues)
    - Highlighting (customizable colors)
    - Beats column (editable for easier position creation)
    - Autoscroll to have the current position always in view
    - Loop (with setting for an offset)
    - PDF generation (Cmd+P)
    - Export positions to share with others - Compatible with ClogAmp & [ClogAmp2](https://www.clogamp.de/en/) (Windows)
- Resizable Clock (Cmd+T)
- Countdown (Cmd+D)
- History (with PDF generation - Cmd+P)
- Playlists (Cmd+L)
- Simple Equalizer (Cmd+E)
- Calculate BPM (automatically or via Cmd+B)
- Beats Player (experimental - hear how a step sounds like - Tools => Beats Player)
- Integrated with MacOS Media Keys and Control Center

## Screenshots
<img src="https://raw.githubusercontent.com/lunk22/ClogAmpSwift/refs/heads/master/Screenshots/ClogAmpMacMainWindow.png" width="500">
<img src="https://raw.githubusercontent.com/lunk22/ClogAmpSwift/refs/heads/master/Screenshots/ClogAmpMacPositions.png" width="500">


## Used libraries / Frameworks:
- [id3Lib](http://id3lib.sourceforge.net/) => Read mp3 info
- [BASS & BASS FX](http://www.un4seen.com/) => Determine BPM
- [SwiftyStringScore](https://github.com/yichizhang/SwiftyStringScore) - [License](https://github.com/yichizhang/SwiftyStringScore/blob/master/LICENSE) => Find matching PDFs
- [Sparkle](https://sparkle-project.org/) - [GitHub](https://github.com/sparkle-project/Sparkle) - [License](https://github.com/sparkle-project/Sparkle/blob/master/LICENSE) => Version updates
- [swift-html-to-pdf](https://github.com/coenttb/swift-html-to-pdf/) - [License](https://github.com/coenttb/swift-html-to-pdf/blob/main/LICENCE) => Convert Positions/History to PDF