enum TranscriptionEngine {
  openAi,
  local,
}

extension TranscriptionEngineLabel on TranscriptionEngine {
  String get label {
    switch (this) {
      case TranscriptionEngine.openAi:
        return 'OpenAI API';
      case TranscriptionEngine.local:
        return 'On-device model';
    }
  }
}
