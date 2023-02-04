class MemoEntity {
  final int? id;
  final String? title;
  final String? author;
  final String? content;
  final String? madeDateTime;
  final String? modifiedDataTime;

  MemoEntity({
    this.id,
    this.title,
    this.author,
    this.content,
    this.madeDateTime,
    this.modifiedDataTime,
  });

  factory MemoEntity.fromJson(Map<String, dynamic> json) =>
      MemoEntity(
        id: json['id'],
        title: json['title'],
        author: json['author'],
        content: json['content'],
        madeDateTime: json['madeDateTime'],
        modifiedDataTime: json['modifiedDataTime'],
      );

  Map<String, dynamic> toJson() =>
      {
        'id': id,
        'title': title,
        'author': author,
        'content': content,
        'madeDateTime': madeDateTime,
        'modifiedDataTime': modifiedDataTime,
      };
}
