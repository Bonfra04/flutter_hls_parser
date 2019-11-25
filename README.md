# flutter_hls_parser

dart plugin for parse m3u8 file for hls.
both of master and media file is supported.

## Getting Started

```dart

Uri playlistUri;
List<String> lines;
try {
  playList = await HlsPlaylistParser.parse(playlistUri, lines);
} on ParserException catch (e) {
  print(e);
}

if (playlist is HlsMasterPlaylist) {
  // master m3u8 file
} else if (playlist is HlsMediaPlaylist) {
  // media m3u8 file
}
```

# MasterPlaylist example
```dart
HlsMasterPlaylist playlist;

playlist.variants[0].format.bitrate;// => 1280000
Util.splitCodec(playlist.variants[0].format.codecs);// => ['mp4a.40.2']['avc1.66.30']
playlist.variants[0].format.width;// => 304(px)
playlist.subtitles[0].format.id;// => sub1:Eng
playlist.audios[0].format.sampleMimeType// => MimeTypes.AUDIO_AC3
```

# MediaPlaylist example
```dart
HlsMediaPlaylist playlist;

playlist.version;// => 3
playlist.hasEndTag;// => true
playlist.segments[0].durationUs;// => 7975000(microsec)
playlist.segments[0].encryptionIV;// => '0x1566B'
playlist.segments[0].drmInitData.schemeData[0].uuid;// => uuid string
```

# Note
all bool param is nonnull, and others are often nullable if unknown.