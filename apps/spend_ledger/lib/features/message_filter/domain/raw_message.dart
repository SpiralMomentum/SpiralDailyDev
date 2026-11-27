import 'package:equatable/equatable.dart';

enum MessageSource { iosShortcut, androidSms, androidApp, share, manual }

class RawMessage extends Equatable {
  const RawMessage({
    required this.text,
    required this.receivedAt,
    required this.source,
    this.sender,
  });

  final String text;
  final String? sender;
  final DateTime receivedAt;
  final MessageSource source;

  @override
  List<Object?> get props => [text, sender, receivedAt, source];
}
