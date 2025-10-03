class AudioRecording {
  const AudioRecording({
    required this.bytes,
    required this.duration,
  });

  final List<int> bytes;
  final Duration duration;
}
