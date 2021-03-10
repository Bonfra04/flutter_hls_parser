import 'drm_init_data.dart';
import 'metadata.dart';
import 'util.dart';

/// Representation of a media format.
class Format {
  Format({
    this.id,
    this.label,
    this.selectionFlags,
    this.roleFlags,
    this.bitrate,
    this.codecs,
    this.metadata,
    this.containerMimeType,
    this.sampleMimeType,
    this.drmInitData,
    this.subsampleOffsetUs,
    this.width,
    this.height,
    this.frameRate,
    this.channelCount,
    String? language,
    this.accessibilityChannel,
  }) : language = language?.toLowerCase();

  factory Format.createVideoContainerFormat({
    String? id,
    String? label,
    String? containerMimeType,
    String? sampleMimeType,
    required String? codecs,
    int? bitrate,
    required int? width,
    required int? height,
    required double? frameRate,
    int selectionFlags = Util.SELECTION_FLAG_DEFAULT,
    int? roleFlags,
  }) =>
      Format(
        id: id,
        label: label,
        selectionFlags: selectionFlags,
        bitrate: bitrate,
        codecs: codecs,
        containerMimeType: containerMimeType,
        sampleMimeType: sampleMimeType,
        width: width,
        height: height,
        frameRate: frameRate,
        roleFlags: roleFlags,
      );

  /// An identifier for the format, or null if unknown or not applicable.
  final String? id;

  /// The human readable label, or null if unknown or not applicable.
  final String? label;

  /// Track selection flags.
  /// [Util.SELECTION_FLAG_DEFAULT] or [Util.SELECTION_FLAG_FORCED] or [Util.SELECTION_FLAG_AUTOSELECT]
  final int? selectionFlags;

  /// Track role flags.
  /// [Util.ROLE_FLAG_DESCRIBES_MUSIC_AND_SOUND] or [Util.ROLE_FLAG_DESCRIBES_VIDEO] or [Util.ROLE_FLAG_EASY_TO_READ] or [Util.ROLE_FLAG_TRANSCRIBES_DIALOG]
  final int? roleFlags;

  /// The average bandwidth in bits per second, or null if unknown or not applicable.
  final int? bitrate;

  /// Codecs of the format as described in RFC 6381, or null if unknown or not applicable.
  final String? codecs;

  /// Metadata, or null if unknown or not applicable.
  final Metadata? metadata;

  /// The mime type of the container, or null if unknown or not applicable.
  final String? containerMimeType;

  ///The mime type of the elementary stream (i.e. the individual samples), or null if unknown or not applicable.
  final String? sampleMimeType;

  ///DRM initialization data if the stream is protected, or null otherwise.
  final DrmInitData? drmInitData;

  //todo ここ追加で検討
  /// For samples that contain subsamples, this is an offset that should be added to subsample timestamps.
  /// A value of {@link #OFFSET_SAMPLE_RELATIVE} indicates that subsample timestamps are relative to the timestamps of their parent samples.
  final int? subsampleOffsetUs;

  /// The width of the video in pixels, or null if unknown or not applicable.
  final int? width;

  /// The height of the video in pixels, or null if unknown or not applicable.
  final int? height;

  /// The frame rate in frames per second, or null if unknown or not applicable.
  final double? frameRate;

  /// The number of audio channels, or null if unknown or not applicable.
  final int? channelCount;

  /// The language of the video, or null if unknown or not applicable.
  final String? language;

  /// The Accessibility channel, or null if not known or applicable.
  final int? accessibilityChannel;

  Format copyWithMetadata(Metadata metadata) => Format(
        id: id,
        label: label,
        selectionFlags: selectionFlags,
        roleFlags: roleFlags,
        bitrate: bitrate,
        codecs: codecs,
        metadata: metadata,
        containerMimeType: containerMimeType,
        sampleMimeType: sampleMimeType,
        drmInitData: drmInitData,
        subsampleOffsetUs: subsampleOffsetUs,
        width: width,
        height: height,
        frameRate: frameRate,
        channelCount: channelCount,
        language: language,
        accessibilityChannel: accessibilityChannel,
      );
}
