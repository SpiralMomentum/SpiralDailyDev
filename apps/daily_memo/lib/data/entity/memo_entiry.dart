class MemoEntity {
  final int? id;
  final String? title;
  final String? author;
  final String? content;
  final String? madeDateTime;
  final String? modifiedDateTime;

  MemoEntity({
    this.id,
    this.title,
    this.author,
    this.content,
    this.madeDateTime,
    this.modifiedDateTime,
  });

  factory MemoEntity.fromJson(Map<String, dynamic> json) => MemoEntity(
        id: json['id'],
        title: json['title'],
        author: json['author'],
        content: json['content'],
        madeDateTime: json['madeDateTime'],
        modifiedDateTime: json['modifiedDateTime'],
      );

  MemoEntity copyWith({
    int? id,
    String? title,
    String? author,
    String? content,
    String? madeDateTime,
    String? modifiedDateTime,
  }) =>
      MemoEntity(
        id: id ?? this.id,
        title: title ?? this.title,
        author: author ?? this.author,
        content: content ?? this.content,
        madeDateTime: madeDateTime ?? this.madeDateTime,
        modifiedDateTime: modifiedDateTime ?? this.modifiedDateTime,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'content': content,
        'madeDateTime': madeDateTime,
        'modifiedDateTime': modifiedDateTime,
      };
}
