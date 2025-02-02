interface class Info {
  final String title;
  final String thumbnail;
  final String place;
  final String description;
  final DateTime startTime;
  final DateTime endTime;

  Info(
    this.title,
    this.thumbnail,
    this.place,
    this.description,
    this.startTime,
    this.endTime,
  );
}
