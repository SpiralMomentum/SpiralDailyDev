class TranscriptionResult {
  const TranscriptionResult({
    required this.id,
    required this.text,
    required this.engineLabel,
    required this.copiedToClipboard,
  });

  final String id;
  final String text;
  final String engineLabel;
  final bool copiedToClipboard;

  TranscriptionResult copyWith({
    String? text,
    bool? copiedToClipboard,
  }) {
    return TranscriptionResult(
      id: id,
      text: text ?? this.text,
      engineLabel: engineLabel,
      copiedToClipboard: copiedToClipboard ?? this.copiedToClipboard,
    );
  }
}
