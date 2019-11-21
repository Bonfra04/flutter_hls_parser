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

class HlsPlaylistParser {
  HlsPlaylistParser(this.masterPlaylist);

  factory HlsPlaylistParser.create({MasterPlaylist masterPlaylist}) {
    masterPlaylist ??= MasterPlaylist.EMPTY;
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

  final MasterPlaylist masterPlaylist;

  HlsPlaylist parse(Uri uri, Stream<List<int>> stream) {
    HlsPlaylist hlsPlaylist;
    bool isFirstLine = false;

    List<String> extraLines = []; // ignore: always_specify_types
    stream.transform(utf8.decoder).transform(const LineSplitter()).listen(
        (String line) {
      if (line.trim().isNotEmpty && hlsPlaylist != null) {
        if (isFirstLine) {
          if (!checkPlaylistHeader(line)) {
            throw UnrecognizedInputFormatException(
                'Input does not start with the #EXTM3U header.', uri);
          }
          isFirstLine = true;
        }

        if (line.startsWith(TAG_STREAM_INF)) {
          extraLines.add(line);
          hlsPlaylist = parseMasterPlaylist(
              LineIterator(extraLines, reader), uri.toString());
        } else {
          if (line.startsWith(TAG_TARGET_DURATION) ||
              line.startsWith(TAG_MEDIA_SEQUENCE) ||
              line.startsWith(TAG_MEDIA_DURATION) ||
              line.startsWith(TAG_KEY) ||
              line.startsWith(TAG_BYTERANGE) ||
              line == TAG_DISCONTINUITY ||
              line == TAG_DISCONTINUITY_SEQUENCE ||
              line == TAG_ENDLIST) {
            extraLines.add(line);
            hlsPlaylist = parseMediaPlaylist(masterPlaylist,
                LineIterator(extraLines, reader), uri.toString());
          } else {
            extraLines.add(line);
          }
        }
      }
    }, onDone: () {
      if (hlsPlaylist == null)
        throw UnrecognizedInputFormatException(
            'Input does not start with the #EXTM3U header.', uri);
    });
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

  MasterPlaylist parseMasterPlaylist(List<String> extraLines) {
    List<String> tags = []; // ignore: always_specify_types
    List<String> mediaTags = []; // ignore: always_specify_types
    List<DrmInitData> sessionKeyDrmInitData =
        []; // ignore: always_specify_types
    List<Variant> variants = []; // ignore: always_specify_types
    Map<Uri, List<VariantInfo>> urlToVariantInfos =
        {}; // ignore: always_specify_types
    bool noClosedCaptions = false;
    bool hasIndependentSegmentsTag = false;

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
}
