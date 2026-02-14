final class SecureFile {
  static const String serviceKey = String.fromEnvironment(
    'SEOUL_API_KEY',
    defaultValue: '',
  );
  static const String serviceName = 'ListExhibitionOfSeoulMOAInfo';
}