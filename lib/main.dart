import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'drm_init_data.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hls_parser/flutter_hls_parser.dart';
import 'exception.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:collection';
import 'package:quiver/strings.dart';
import 'util.dart';
import 'play_list.dart';
import 'mime_types.dart';
import 'scheme_data.dart';
import 'format.dart';
import 'variant.dart';
import 'variant_info.dart';
import 'hls_track_metadata_entry.dart';
import 'metadata.dart';
import 'rendition.dart';
import 'variant.dart';
import 'hls_master_playlist.dart';
import 'hls_media_playlist.dart';
import 'segment.dart';

class HlsPlaylistParser {
  HlsPlaylistParser(this.masterPlaylist);

  factory HlsPlaylistParser.create({HlsMasterPlaylist masterPlaylist}) {
    masterPlaylist ??= HlsMasterPlaylist();
    return HlsPlaylistParser(masterPlaylist);
  }

  static const String PLAYLIST_HEADER = '#EXTM3U';
  static const String TAG_PREFIX = '#EXT';
  static const String TAG_VERSION = '#EXT-X-VERSION';
  static const String TAG_PLAYLIST_TYPE = '#EXT-X-PLAYLIST-TYPE';
  static const String TAG_DEFINE = '#EXT-X-DEFINE';
  static const String TAG_STREAM_INF = '#EXT-X-STREAM-INF';
  static const String TAG_MEDIA = '#EXT-X-MEDIA';
  static const String TAG_TARGET_DURATION = '#EXT-X-TARGETDURATION';
  static const String TAG_DISCONTINUITY = '#EXT-X-DISCONTINUITY';
  static const String TAG_DISCONTINUITY_SEQUENCE =
      '#EXT-X-DISCONTINUITY-SEQUENCE';
  static const String TAG_PROGRAM_DATE_TIME = '#EXT-X-PROGRAM-DATE-TIME';
  static const String TAG_INIT_SEGMENT = '#EXT-X-MAP';
  static const String TAG_INDEPENDENT_SEGMENTS = '#EXT-X-INDEPENDENT-SEGMENTS';
  static const String TAG_MEDIA_DURATION = '#EXTINF';
  static const String TAG_MEDIA_SEQUENCE = '#EXT-X-MEDIA-SEQUENCE';
  static const String TAG_START = '#EXT-X-START';
  static const String TAG_ENDLIST = '#EXT-X-ENDLIST';
  static const String TAG_KEY = '#EXT-X-KEY';
  static const String TAG_SESSION_KEY = '#EXT-X-SESSION-KEY';
  static const String TAG_BYTERANGE = '#EXT-X-BYTERANGE';
  static const String TAG_GAP = '#EXT-X-GAP';
  static const String TYPE_AUDIO = 'AUDIO';
  static const String TYPE_VIDEO = 'VIDEO';
  static const String TYPE_SUBTITLES = 'SUBTITLES';
  static const String TYPE_CLOSED_CAPTIONS = 'CLOSED-CAPTIONS';
  static const String METHOD_NONE = 'NONE';
  static const String METHOD_AES_128 = 'AES-128';
  static const String METHOD_SAMPLE_AES = 'SAMPLE-AES';
  static const String METHOD_SAMPLE_AES_CENC = 'SAMPLE-AES-CENC';
  static const String METHOD_SAMPLE_AES_CTR = 'SAMPLE-AES-CTR';
  static const String KEYFORMAT_PLAYREADY = 'com.microsoft.playready';
  static const String KEYFORMAT_IDENTITY = 'identity';
  static const String KEYFORMAT_WIDEVINE_PSSH_BINARY =
      'urn:uuid:edef8ba9-79d6-4ace-a3c8-27dcd51d21ed';
  static const String KEYFORMAT_WIDEVINE_PSSH_JSON = 'com.widevine';
  static const String BOOLEAN_TRUE = 'YES';
  static const String BOOLEAN_FALSE = 'NO';
  static const String ATTR_CLOSED_CAPTIONS_NONE = 'CLOSED-CAPTIONS=NONE';
  static const String REGEX_AVERAGE_BANDWIDTH = 'AVERAGE-BANDWIDTH=(\\d+)\\b';
  static const String REGEX_VIDEO = 'VIDEO="(.+?)"';
  static const String REGEX_AUDIO = 'AUDIO="(.+?)"';
  static const String REGEX_SUBTITLES = 'SUBTITLES="(.+?)"';
  static const String REGEX_CLOSED_CAPTIONS = 'CLOSED-CAPTIONS="(.+?)"';
  static const String REGEX_BANDWIDTH = '[^-]BANDWIDTH=(\\d+)\\b';
  static const String REGEX_CHANNELS = 'CHANNELS="(.+?)"';
  static const String REGEX_CODECS = 'CODECS="(.+?)"';
  static const String REGEX_RESOLUTION = 'RESOLUTION=(\\d+x\\d+)';
  static const String REGEX_FRAME_RATE = 'FRAME-RATE=([\\d\\.]+)\\b';
  static const String REGEX_TARGET_DURATION = '$TAG_TARGET_DURATION:(\\d+)\\b';
  static const String REGEX_VERSION = '$TAG_VERSION:(\\d+)\\b';
  static const String REGEX_PLAYLIST_TYPE = '$TAG_PLAYLIST_TYPE:(.+)\\b';
  static const String REGEX_MEDIA_SEQUENCE = '$TAG_MEDIA_SEQUENCE:(\\d+)\\b';
  static const String REGEX_MEDIA_DURATION =
      '$TAG_MEDIA_DURATION:([\\d\\.]+)\\b';
  static const String REGEX_MEDIA_TITLE =
      '$TAG_MEDIA_DURATION:[\\d\\.]+\\b,(.+)';
  static const String REGEX_TIME_OFFSET = 'TIME-OFFSET=(-?[\\d\\.]+)\\b';
  static const String REGEX_BYTERANGE = '$TAG_BYTERANGE:(\\d+(?:@\\d+)?)\\b';
  static const String REGEX_ATTR_BYTERANGE = 'BYTERANGE="(\\d+(?:@\\d+)?)\\b"';
  static const String REGEX_METHOD =
      'METHOD=($METHOD_NONE|$METHOD_AES_128|$METHOD_SAMPLE_AES|$METHOD_SAMPLE_AES_CENC|$METHOD_SAMPLE_AES_CTR)\\s*(?:,|\$)';
  static const String REGEX_KEYFORMAT = 'KEYFORMAT="(.+?)"';
  static const String REGEX_KEYFORMATVERSIONS = 'KEYFORMATVERSIONS="(.+?)"';
  static const String REGEX_URI = 'URI="(.+?)"';
  static const String REGEX_IV = 'IV=([^,.*]+)';
  static const String REGEX_TYPE =
      'TYPE=($TYPE_AUDIO)|$TYPE_VIDEO|$TYPE_SUBTITLES|$TYPE_CLOSED_CAPTIONS)';
  static const String REGEX_LANGUAGE = 'LANGUAGE="(.+?)"';
  static const String REGEX_NAME = 'NAME="(.+?)"';
  static const String REGEX_GROUP_ID = 'GROUP-ID="(.+?)"';
  static const String REGEX_CHARACTERISTICS = 'CHARACTERISTICS="(.+?)"';
  static const String REGEX_INSTREAM_ID = 'INSTREAM-ID="((?:CC|SERVICE)\\d+)"';
  static final String REGEX_AUTOSELECT =
      _compileBooleanAttrPattern('AUTOSELECT');
  static final String REGEX_DEFAULT = _compileBooleanAttrPattern('DEFAULT');
  static final String REGEX_FORCED = _compileBooleanAttrPattern('FORCED');
  static const String REGEX_VALUE = 'VALUE="(.+?)"';
  static const String REGEX_IMPORT = 'IMPORT="(.+?)"';
  static const String REGEX_VARIABLE_REFERENCE = '\\{\\\$([a-zA-Z0-9\\-_]+)\\}';

  final HlsMasterPlaylist masterPlaylist;

  Future<HlsPlaylist> parse(Uri uri, Stream<List<int>> stream) async {
    List<String> lineList = await stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .where((line) => line.trim().isNotEmpty) // ignore: always_specify_types
        .toList();

    if (!checkPlaylistHeader(lineList[0]))
      throw UnrecognizedInputFormatException(
          'Input does not start with the #EXTM3U header.', uri);

    List<String> extraLines =
        lineList.getRange(1, lineList.length - 1).toList();

    return lineList.last.startsWith(TAG_STREAM_INF)
        ? parseMasterPlaylist(extraLines, uri.toString())
        : parseMediaPlaylist(masterPlaylist, extraLines, uri.toString());
  }

  static String _compileBooleanAttrPattern(String attribute) =>
      '$attribute=($BOOLEAN_FALSE|$BOOLEAN_TRUE)';

  static bool checkPlaylistHeader(String string) {
    List<int> codeUnits =
        Util.excludeWhiteSpace(string: string, skipLinebreaks: true).codeUnits;

    if (codeUnits[0] == 0xEF) {
      if (Util.startsWith(
          codeUnits, [0xEF, 0xBB, 0xBF])) // ignore: always_specify_types
        return false;
      codeUnits =
          codeUnits.getRange(5, codeUnits.length - 1).toList(); //不要な文字が含まれている
    }

    if (!Util.startsWith(codeUnits, PLAYLIST_HEADER.runes.toList()))
      return false;

    return Util.isLineBreak(codeUnits[PLAYLIST_HEADER.length]);
  }

  HlsMasterPlaylist parseMasterPlaylist(
      List<String> extraLines, String baseUri) {
    List<String> tags = []; // ignore: always_specify_types
    List<String> mediaTags = []; // ignore: always_specify_types
    List<DrmInitData> sessionKeyDrmInitData =
        []; // ignore: always_specify_types
    List<Variant> variants = []; // ignore: always_specify_types
    List<Rendition> videos = [];
    List<Rendition> audios = [];
    List<Rendition> subtitles = [];
    List<Rendition> closedCaptions = [];
    Map<Uri, List<VariantInfo>> urlToVariantInfos =
        {}; // ignore: always_specify_types
    Format muxedAudioFormat;
    bool noClosedCaptions = false;
    bool hasIndependentSegmentsTag = false;
    List<Format> muxedCaptionFormats;

    Map<String, String> variableDefinitions =
        {}; // ignore: always_specify_types
    for (final String line in extraLines) {
      if (line.startsWith(TAG_PREFIX)) {
        // We expose all tags through the playlist.
        tags.add(line);
      }

      if (line.startsWith(TAG_DEFINE)) {
        String key = parseStringAttr(
            source: line,
            pattern: REGEX_NAME,
            variableDefinitions: variableDefinitions);
        String val = parseStringAttr(
            source: line,
            pattern: REGEX_VALUE,
            variableDefinitions: variableDefinitions);
        if (key == null) {
          throw ParserException("Couldn't match $REGEX_NAME in $line");
        }
        if (val == null) {
          throw ParserException("Couldn't match $REGEX_VALUE in $line");
        }
        variableDefinitions[key] = val;
      } else if (line == TAG_INDEPENDENT_SEGMENTS) {
        hasIndependentSegmentsTag = true;
      } else if (line.startsWith(TAG_MEDIA)) {
        mediaTags.add(line);
      } else if (line.startsWith(TAG_STREAM_INF)) {
        String keyFormat = parseStringAttr(
            source: line,
            pattern: REGEX_KEYFORMAT,
            defaultValue: KEYFORMAT_IDENTITY,
            variableDefinitions: variableDefinitions);
        SchemeData schemeData = parseDrmSchemeData(
            line: line,
            keyFormat: keyFormat,
            variableDefinitions: variableDefinitions);

        if (schemeData != null) {
          String method = parseStringAttr(
              source: line,
              pattern: REGEX_METHOD,
              variableDefinitions: variableDefinitions);
          String scheme = parseEncryptionScheme(method);
          DrmInitData drmInitData = DrmInitData(
              schemeType: scheme,
              schemeData: [schemeData]); // ignore: always_specify_types
          sessionKeyDrmInitData.add(drmInitData);
        }
      } else if (line.startsWith(TAG_STREAM_INF)) {
        noClosedCaptions |= line.contains(ATTR_CLOSED_CAPTIONS_NONE); //todo 再検討
        int bitrate = parseIntAttr(line, REGEX_BANDWIDTH);
        String averageBandwidthString = parseStringAttr(
            source: line,
            pattern: REGEX_AVERAGE_BANDWIDTH,
            variableDefinitions: variableDefinitions);
        if (averageBandwidthString != null)
          // If available, the average bandwidth attribute is used as the variant's bitrate.
          bitrate = int.parse(averageBandwidthString);
        String codecs = parseStringAttr(
            source: line,
            pattern: REGEX_CODECS,
            variableDefinitions: variableDefinitions);
        String resolutionString = parseStringAttr(
            source: line,
            pattern: REGEX_RESOLUTION,
            variableDefinitions: variableDefinitions);
        int width;
        int height;
        if (resolutionString != null) {
          List<String> widthAndHeight = resolutionString.split('x');
          width = int.parse(widthAndHeight[0]);
          height = int.parse(widthAndHeight[1]);
          if (width <= 0 || height <= 0) {
            // Resolution string is invalid.
            width = Format.NO_VALUE;
            height = Format.NO_VALUE;
          }
        }

        double frameRate = Format.NO_VALUE.toDouble();
        String frameRateString = parseStringAttr(
            source: line,
            pattern: REGEX_FRAME_RATE,
            variableDefinitions: variableDefinitions);
        if (frameRateString != null) {
          frameRate = double.parse(frameRateString);
        }
        String videoGroupId = parseStringAttr(
            source: line,
            pattern: REGEX_VIDEO,
            variableDefinitions: variableDefinitions);
        String audioGroupId = parseStringAttr(
            source: line,
            pattern: REGEX_AUDIO,
            variableDefinitions: variableDefinitions);
        String subtitlesGroupId = parseStringAttr(
            source: line,
            pattern: REGEX_SUBTITLES,
            variableDefinitions: variableDefinitions);
        String closedCaptionsGroupId = parseStringAttr(
            source: line,
            pattern: REGEX_CLOSED_CAPTIONS,
            variableDefinitions: variableDefinitions);

        String parsedLine = parseStringAttr(
            source: line,
            pattern: REGEX_VARIABLE_REFERENCE,
            variableDefinitions:
                variableDefinitions); // #EXT-X-STREAM-INF's URI.

//        Uri uri = UriUtil.resolveToUri(baseUri, parsedLine);//todo 実装
        Uri uri;

        Format format = Format.createVideoContainerFormat(
            id: variants.length.toString(),
            containerMimeType: MimeTypes.APPLICATION_M3U8,
            codecs: codecs,
            bitrate: bitrate,
            width: width,
            height: height,
            frameRate: frameRate);

        variants.add(Variant(
          url: uri,
          format: format,
          videoGroupId: videoGroupId,
          audioGroupId: audioGroupId,
          subtitleGroupId: subtitlesGroupId,
          captionGroupId: closedCaptionsGroupId,
        ));

        List<VariantInfo> variantInfosForUrl = urlToVariantInfos[uri];
        if (variantInfosForUrl == null) {
          variantInfosForUrl = []; // ignore: always_specify_types
          urlToVariantInfos[uri] = variantInfosForUrl;
        }

        variantInfosForUrl.add(VariantInfo(
          bitrate: bitrate,
          videoGroupId: videoGroupId,
          audioGroupId: audioGroupId,
          subtitleGroupId: subtitlesGroupId,
          captionGroupId: closedCaptionsGroupId,
        ));
      }
    }

    // TODO: Don't deduplicate variants by URL.
    List<Variant> deduplicatedVariants = []; // ignore: always_specify_types
    List<Uri> urlsInDeduplicatedVariants = []; // ignore: always_specify_types
    for (int i = 0; i < variants.length; i++) {
      Variant variant = variants[i];
      urlsInDeduplicatedVariants.add(variant.url);
      assert(variant.format.metadata == null);
      HlsTrackMetadataEntry hlsMetadataEntry =
          HlsTrackMetadataEntry(variantInfos: urlToVariantInfos[variant.url]);
      Metadata metadata = Metadata(<dynamic>[hlsMetadataEntry]);
      deduplicatedVariants.add(
          variant.copyWithFormat(variant.format.copyWithMetadata(metadata)));
    }

    mediaTags.forEach((line) {
      // ignore: always_specify_types
      String groupId = parseStringAttr(
          source: line,
          pattern: REGEX_GROUP_ID,
          variableDefinitions: variableDefinitions);
      String name = parseStringAttr(
          source: line,
          pattern: REGEX_NAME,
          variableDefinitions: variableDefinitions);
      String referenceUri = parseStringAttr(
          source: line,
          pattern: REGEX_URI,
          variableDefinitions: variableDefinitions);
      Uri uri; //todo 実装
//      Uri uri = referenceUri == null ? null : UriUtil.resolveToUri(baseUri, referenceUri);
      String language = parseStringAttr(
          source: line,
          pattern: REGEX_LANGUAGE,
          variableDefinitions: variableDefinitions);
      int selectionFlags = parseSelectionFlags(line);
      int roleFlags = parseRoleFlags(line, variableDefinitions);
      String formatId = '$groupId:$name';
      Format format;
      HlsTrackMetadataEntry entry = HlsTrackMetadataEntry(
          groupId: groupId, name: name, variantInfos: <VariantInfo>[]);
      Metadata metadata = Metadata(<dynamic>[entry]);

      switch (parseStringAttr(
          source: line,
          pattern: REGEX_TYPE,
          variableDefinitions: variableDefinitions)) {
        case TYPE_VIDEO:
          {
            Variant variant = variants.firstWhere(
                (it) => it.videoGroupId == groupId,
                orElse: () => null); // ignore: always_specify_types
            String codecs;
            int width = Format.NO_VALUE;
            int height = Format.NO_VALUE;
            double frameRate = Format.NO_VALUE_D;
            if (variant != null) {
              Format variantFormat = variant.format;
              codecs = Util.getCodecsOfType(
                  variantFormat.codecs, Util.TRACK_TYPE_VIDEO);
              width = variantFormat.width;
              height = variantFormat.height;
              frameRate = variantFormat.frameRate;
            }
            String sampleMimeType =
                codecs != null ? MimeTypes.getMediaMimeType(codecs) : null;

            format = Format.createVideoContainerFormat(
                    id: formatId,
                    label: name,
                    containerMimeType: MimeTypes.APPLICATION_M3U8,
                    sampleMimeType: sampleMimeType,
                    codecs: codecs,
                    bitrate: Format.NO_VALUE,
                    width: width,
                    height: height,
                    frameRate: frameRate,
                    selectionFlags: selectionFlags,
                    roleFlags: roleFlags)
                .copyWithMetadata(metadata);

            videos.add(Rendition(
              url: uri,
              format: format,
              groupId: groupId,
              name: name,
            ));
            break;
          }
        case TYPE_AUDIO:
          {
            Variant variant = getVariantWithAudioGroup(variants, groupId);
            String codecs = variant != null
                ? Util.getCodecsOfType(
                    variant.format.codecs, Util.TRACK_TYPE_AUDIO)
                : null;
            int channelCount =
                parseChannelsAttribute(line, variableDefinitions);
            String sampleMimeType =
                codecs != null ? MimeTypes.getMediaMimeType(codecs) : null;
            Format format = Format.create(
              id: formatId,
              label: name,
              containerMimeType: MimeTypes.APPLICATION_M3U8,
              sampleMimeType: sampleMimeType,
              codecs: codecs,
              bitrate: Format.NO_VALUE,
              channelCount: channelCount,
              selectionFlags: selectionFlags,
              roleFlags: roleFlags,
              language: language,
            );

            if (uri == null)
              muxedAudioFormat = format;
            else
              audios.add(Rendition(
                url: uri,
                format: format.copyWithMetadata(metadata),
                groupId: groupId,
                name: name,
              ));
            break;
          }
        case TYPE_SUBTITLES:
          {
            Format format = Format.create(
                    id: formatId,
                    label: name,
                    containerMimeType: MimeTypes.APPLICATION_M3U8,
                    sampleMimeType: MimeTypes.TEXT_VTT,
                    selectionFlags: selectionFlags,
                    roleFlags: roleFlags,
                    language: language)
                .copyWithMetadata(metadata);
            subtitles.add(Rendition(
              url: uri,
              format: format,
              groupId: groupId,
              name: name,
            ));
            break;
          }
        default:
          break;
      }
    });

    if (noClosedCaptions)
      muxedCaptionFormats = []; // ignore: always_specify_types

    return HlsMasterPlaylist(
        baseUri: baseUri,
        tags: tags,
        variants: deduplicatedVariants,
        videos: videos,
        audios: audios,
        subtitles: subtitles,
        closedCaptions: closedCaptions,
        muxedAudioFormat: muxedAudioFormat,
        muxedCaptionFormats: muxedCaptionFormats,
        hasIndependentSegments: hasIndependentSegmentsTag,
        variableDefinitions: variableDefinitions,
        sessionKeyDrmInitData: sessionKeyDrmInitData);
  }

  static String parseStringAttr({
    @required String source,
    @required String pattern,
    String defaultValue,
    Map<String, String> variableDefinitions,
  }) {
    String value = RegExp(pattern).firstMatch(source)?.group(1);
    value ??= defaultValue;
    return value?.replaceAllMapped(REGEX_VARIABLE_REFERENCE, (Match match) {
      String key = match.group(1);
      return variableDefinitions[key] ??= key;
    });
  }

  static SchemeData parseDrmSchemeData(
      {String line,
      String keyFormat,
      Map<String, String> variableDefinitions}) {
    String keyFormatVersions = parseStringAttr(
      source: line,
      pattern: REGEX_KEYFORMATVERSIONS,
      defaultValue: '1',
      variableDefinitions: variableDefinitions,
    );

    if (KEYFORMAT_WIDEVINE_PSSH_BINARY == keyFormat) {
      String uriString = parseStringAttr(
          source: line,
          pattern: REGEX_URI,
          variableDefinitions: variableDefinitions);
      Uint8List data = getBase64FromUri(uriString);
      return SchemeData(
          uuid: '', //todo 保留
          mimeType: MimeTypes.VIDEO_MP4,
          data: data);
    } else if (KEYFORMAT_WIDEVINE_PSSH_JSON == keyFormat) {
      return SchemeData(
          uuid: '', //todo 保留
          mimeType: MimeTypes.HLS,
          data: const Utf8Encoder().convert(line));
    } else if (KEYFORMAT_PLAYREADY == keyFormat && '1' == keyFormatVersions) {
      String uriString = parseStringAttr(
          source: line,
          pattern: REGEX_URI,
          variableDefinitions: variableDefinitions);
      Uint8List data = getBase64FromUri(uriString);
      Uint8List psshData; //todo 保留
      return SchemeData(
          uuid: '' /*保留*/, mimeType: MimeTypes.VIDEO_MP4, data: psshData);
    }

    return null;
  }

  static int parseSelectionFlags(String line) {
    int flags = 0;
    if (parseOptionalBooleanAttribute(
        line: line,
        pattern: REGEX_DEFAULT,
        defaultValue: false)) flags |= Util.SELECTION_FLAG_DEFAULT;
    if (parseOptionalBooleanAttribute(
        line: line,
        pattern: REGEX_FORCED,
        defaultValue: false)) flags |= Util.SELECTION_FLAG_FORCED;
    if (parseOptionalBooleanAttribute(
        line: line,
        pattern: REGEX_AUTOSELECT,
        defaultValue: false)) flags |= Util.SELECTION_FLAG_AUTOSELECT;
    return flags;
  }

  static bool parseOptionalBooleanAttribute({
    @required String line,
    @required String pattern,
    @required bool defaultValue,
  }) {
    List<Match> list = line.allMatches(pattern).toList();
    return list.isEmpty ? defaultValue : list.first.pattern == BOOLEAN_TRUE;
  }

  static int parseRoleFlags(
      String line, Map<String, String> variableDefinitions) {
    String concatenatedCharacteristics = parseStringAttr(
        source: line,
        pattern: REGEX_CHARACTERISTICS,
        variableDefinitions: variableDefinitions);
    if (concatenatedCharacteristics?.isNotEmpty == false) return 0;
    List<String> characteristics = concatenatedCharacteristics.split(',');
    int roleFlags = 0;
    if (characteristics.contains('public.accessibility.describes-video'))
      roleFlags |= Util.ROLE_FLAG_DESCRIBES_VIDEO;

    if (characteristics
        .contains('public.accessibility.transcribes-spoken-dialog'))
      roleFlags |= Util.ROLE_FLAG_TRANSCRIBES_DIALOG;

    if (characteristics
        .contains('public.accessibility.describes-music-and-sound'))
      roleFlags |= Util.ROLE_FLAG_DESCRIBES_MUSIC_AND_SOUND;

    if (characteristics.contains('public.easy-to-read'))
      roleFlags |= Util.ROLE_FLAG_EASY_TO_READ;

    return roleFlags;
  }

  static int parseChannelsAttribute(
      String line, Map<String, String> variableDefinitions) {
    String channelsString = parseStringAttr(
        source: line,
        pattern: REGEX_CHANNELS,
        variableDefinitions: variableDefinitions);
    return channelsString != null
        ? int.parse(channelsString.split('/')[0])
        : Format.NO_VALUE;
  }

  static Variant getVariantWithAudioGroup(
      List<Variant> variants, String groupId) {
    for (var variant in variants)
      if (variant.audioGroupId == groupId) return variant;
    return null;
  }

  static String parseEncryptionScheme(String method) =>
      METHOD_SAMPLE_AES_CENC == method || METHOD_SAMPLE_AES_CTR == method
          ? CencType.CENC
          : CencType.CBCS;

  static Uint8List getBase64FromUri(String uriString) {
    String uriPre = uriString.substring(uriString.indexOf(','));
    return const Base64Decoder().convert(uriPre);
  }

  static int parseIntAttr(String line, String pattern) =>
      int.parse(parseStringAttr(
        source: line,
        pattern: pattern,
        variableDefinitions: {}, // ignore: always_specify_types
      ));

  static HlsMediaPlaylist parseMediaPlaylist(HlsMasterPlaylist masterPlaylist,
      List<String> extraLines, String baseUri) {
    int playlistType = HlsMediaPlaylist.PLAYLIST_TYPE_UNKNOWN;
    int startOffsetUs = Util.TIME_UNSET;
    int mediaSequence = 0;
    int version = 1; // Default version == 1.
    int targetDurationUs = Util.TIME_UNSET;
    bool hasIndependentSegmentsTag = masterPlaylist.hasIndependentSegments;
    bool hasEndTag = false;
    int segmentByteRangeOffset = 0;
    Segment initializationSegment;
    Map<String, String> variableDefinitions = {};
    List<Segment> segments = [];
    List<String> tags = []; // ignore: always_specify_types
    int segmentByteRangeLength = Util.LENGTH_UNSET;
    int segmentMediaSequence = 0;
    int segmentDurationUs = 0;
    String segmentTitle = '';
    Map<String, SchemeData> currentSchemeDatas =
        {}; // ignore: always_specify_types
    DrmInitData cachedDrmInitData;
    String encryptionScheme;
    DrmInitData playlistProtectionSchemes;
    bool hasDiscontinuitySequence = false;
    int playlistDiscontinuitySequence = 0;
    int relativeDiscontinuitySequence = 0;
    int playlistStartTimeUs = 0;
    int segmentStartTimeUs = 0;
    bool hasGapTag = false;

    String fullSegmentEncryptionKeyUri;
    String fullSegmentEncryptionIV;

    for (var line in extraLines) {
      if (line.startsWith(TAG_PREFIX)) {
        // We expose all tags through the playlist.
        tags.add(line);
      }

      if (line.startsWith(TAG_PLAYLIST_TYPE)) {
        String playlistTypeString = parseStringAttr(
            source: line,
            pattern: REGEX_PLAYLIST_TYPE,
            variableDefinitions: variableDefinitions);
        if ('VOD' == playlistTypeString) {
          playlistType = HlsMediaPlaylist.PLAYLIST_TYPE_VOD;
        } else if ('EVENT' == playlistTypeString) {
          playlistType = HlsMediaPlaylist.PLAYLIST_TYPE_EVENT;
        }
      } else if (line.startsWith(TAG_START)) {
        String string = parseStringAttr(
            source: line,
            pattern: REGEX_TIME_OFFSET,
            variableDefinitions: {}); // ignore: always_specify_types
        startOffsetUs = (double.parse(string) * 1000000).toInt();
      } else if (line.startsWith(TAG_INIT_SEGMENT)) {
        String uri = parseStringAttr(
            source: line,
            pattern: REGEX_URI,
            variableDefinitions: variableDefinitions);
        String byteRange = parseStringAttr(
            source: line,
            pattern: REGEX_ATTR_BYTERANGE,
            variableDefinitions: variableDefinitions);
        if (byteRange != null) {
          List<String> splitByteRange = byteRange.split('@');
          segmentByteRangeLength = int.parse(splitByteRange[0]);
          if (splitByteRange.length > 1) {
            segmentByteRangeOffset = int.parse(splitByteRange[1]);
          }
        }

        if (fullSegmentEncryptionKeyUri != null &&
            fullSegmentEncryptionIV == null)
          // See RFC 8216, Section 4.3.2.5.
          throw ParserException(
              'The encryption IV attribute must be present when an initialization segment is encrypted with METHOD=AES-128.');

        initializationSegment = Segment(
            url: uri,
            byterangeOffset: segmentByteRangeOffset,
            byterangeLength: segmentByteRangeLength,
            fullSegmentEncryptionKeyUri: fullSegmentEncryptionKeyUri,
            encryptionIV: fullSegmentEncryptionIV);
        segmentByteRangeOffset = 0;
        segmentByteRangeLength = Util.LENGTH_UNSET;
      } else if (line.startsWith(TAG_TARGET_DURATION)) {
        targetDurationUs = int.parse(
            parseStringAttr(source: line, pattern: REGEX_TARGET_DURATION) *
                100000);
      } else if (line.startsWith(TAG_MEDIA_SEQUENCE)) {
        mediaSequence = int.parse(
            parseStringAttr(source: line, pattern: REGEX_MEDIA_SEQUENCE));
        segmentMediaSequence = mediaSequence;
      } else if (line.startsWith(TAG_VERSION)) {
        version = parseIntAttr(line, REGEX_VERSION);
      } else if (line.startsWith(TAG_DEFINE)) {
        String importName = parseStringAttr(
            source: line,
            pattern: REGEX_IMPORT,
            variableDefinitions: variableDefinitions);
        if (importName != null) {
          String value = masterPlaylist.variableDefinitions[importName];
          if (value != null) {
            variableDefinitions[importName] = value;
          } else {
            // The master playlist does not declare the imported variable. Ignore.
          }
        } else {
          String key = parseStringAttr(
              source: line,
              pattern: REGEX_NAME,
              variableDefinitions: variableDefinitions);
          String value = parseStringAttr(
              source: line,
              pattern: REGEX_VALUE,
              variableDefinitions: variableDefinitions);
          variableDefinitions[key] = value;
        }
      } else if (line.startsWith(TAG_MEDIA_DURATION)) {
        segmentDurationUs = int.parse(
            parseStringAttr(source: line, pattern: REGEX_MEDIA_DURATION) *
                100000);
        segmentTitle = parseStringAttr(
            source: line,
            pattern: REGEX_MEDIA_TITLE,
            defaultValue: '',
            variableDefinitions: variableDefinitions);
      } else if (line.startsWith(TAG_KEY)) {
        String method = parseStringAttr(
            source: line,
            pattern: REGEX_METHOD,
            variableDefinitions: variableDefinitions);
        String keyFormat = parseStringAttr(
            source: line,
            pattern: REGEX_KEYFORMAT,
            defaultValue: KEYFORMAT_IDENTITY,
            variableDefinitions: variableDefinitions);
        fullSegmentEncryptionKeyUri = null;
        fullSegmentEncryptionIV = null;
        if (METHOD_NONE == method) {
          currentSchemeDatas.clear();
          cachedDrmInitData = null;
        } else
        /* !METHOD_NONE.equals(method) */ {
          fullSegmentEncryptionIV = parseStringAttr(
              source: line,
              pattern: REGEX_IV,
              variableDefinitions: variableDefinitions);
          if (KEYFORMAT_IDENTITY == keyFormat) {
            if (METHOD_AES_128 == method) {
              // The segment is fully encrypted using an identity key.
              fullSegmentEncryptionKeyUri = parseStringAttr(
                  source: line,
                  pattern: REGEX_URI,
                  variableDefinitions: variableDefinitions);
            } else {
              // Do nothing. Samples are encrypted using an identity key, but this is not supported.
              // Hopefully, a traditional DRM alternative is also provided.
            }
          } else {
            encryptionScheme ??= parseEncryptionScheme(method);
            SchemeData schemeData = parseDrmSchemeData(
                line: line,
                keyFormat: keyFormat,
                variableDefinitions: variableDefinitions);
            if (schemeData != null) {
              cachedDrmInitData = null;
              currentSchemeDatas[keyFormat] = schemeData;
            }
          }
        }
      } else if (line.startsWith(TAG_BYTERANGE)) {
        String byteRange = parseStringAttr(
            source: line,
            pattern: REGEX_BYTERANGE,
            variableDefinitions: variableDefinitions);
        List<String> splitByteRange = byteRange.split('@');
        segmentByteRangeLength = int.parse(splitByteRange[0]);
        if (splitByteRange.length > 1)
          segmentByteRangeOffset = int.parse(splitByteRange[1]);
      } else if (line.startsWith(TAG_DISCONTINUITY_SEQUENCE)) {
        hasDiscontinuitySequence = true;
        playlistDiscontinuitySequence =
            int.parse(line.substring(line.indexOf(':') + 1));
      } else if (line == TAG_DISCONTINUITY) {
        relativeDiscontinuitySequence++;
      } else if (line.startsWith(TAG_PROGRAM_DATE_TIME)) {
        if (playlistStartTimeUs == 0) {
          int programDatetimeUs =
              Util.parseXsDateTime(line.substring(line.indexOf(':') + 1));
          playlistStartTimeUs = programDatetimeUs - segmentStartTimeUs;
        }
      } else if (line == TAG_GAP) {
        hasGapTag = true;
      } else if (line == TAG_INDEPENDENT_SEGMENTS) {
        hasIndependentSegmentsTag = true;
      } else if (line == TAG_ENDLIST) {
        hasEndTag = true;
      } else if (!line.startsWith('#')) {
        String segmentEncryptionIV;
        if (fullSegmentEncryptionKeyUri == null)
          segmentEncryptionIV = null;
        else if (fullSegmentEncryptionIV != null)
          segmentEncryptionIV = fullSegmentEncryptionIV;
        else
          segmentEncryptionIV = segmentMediaSequence.toRadixString(16);

        segmentMediaSequence++;
        if (segmentByteRangeLength == Util.LENGTH_UNSET)
          segmentByteRangeOffset = 0;

        if (cachedDrmInitData == null && currentSchemeDatas.isNotEmpty) {
          List<SchemeData> schemeDatas = currentSchemeDatas.values.toList();
          cachedDrmInitData = DrmInitData(
              schemeType: encryptionScheme, schemeData: schemeDatas);
          if (playlistProtectionSchemes == null) {
            List<SchemeData> playlistSchemeDatas =
                schemeDatas.map((it) => it.copyWithData(null)).toList();
            playlistProtectionSchemes = DrmInitData(
                schemeType: encryptionScheme, schemeData: playlistSchemeDatas);
          }
        }

        segments.add(Segment(
            url: parseStringAttr(
                source: line,
                pattern: REGEX_VARIABLE_REFERENCE,
                variableDefinitions: variableDefinitions),
            initializationSegment: initializationSegment,
            title: segmentTitle,
            durationUs: segmentDurationUs,
            relativeDiscontinuitySequence: relativeDiscontinuitySequence,
            relativeStartTimeUs: segmentStartTimeUs,
            drmInitData: cachedDrmInitData,
            fullSegmentEncryptionKeyUri: fullSegmentEncryptionKeyUri,
            encryptionIV: fullSegmentEncryptionIV,
            byterangeOffset: segmentByteRangeOffset,
            byterangeLength: segmentByteRangeLength,
            hasGapTag: hasGapTag));

        segmentStartTimeUs += segmentDurationUs;
        segmentDurationUs = 0;
        segmentTitle = '';
        if (segmentByteRangeLength != Util.LENGTH_UNSET)
          segmentByteRangeOffset += segmentByteRangeLength;
        segmentByteRangeLength = Util.LENGTH_UNSET;
        hasGapTag = false;
      }
    }

    return HlsMediaPlaylist.create(
        playlistType: playlistType,
        baseUri: baseUri,
        tags: tags,
        startOffsetUs: startOffsetUs,
        startTimeUs: playlistStartTimeUs,
        hasDiscontinuitySequence: hasDiscontinuitySequence,
        discontinuitySequence: playlistDiscontinuitySequence,
        mediaSequence: mediaSequence,
        version: version,
        targetDurationUs: targetDurationUs,
        hasIndependentSegments: hasIndependentSegmentsTag,
        hasEndTag: hasEndTag,
        hasProgramDateTime: playlistStartTimeUs != 0,
        protectionSchemes: playlistProtectionSchemes,
        segments: segments);
  }
}
