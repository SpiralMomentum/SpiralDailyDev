class AddMemoEntity {
  final String? title;
  final String? author;
  final String? content;
  final String? madeDateTime;
  final String? modifiedDateTime;

  AddMemoEntity({
    this.title,
    this.author,
    this.content,
    this.madeDateTime,
    this.modifiedDateTime,
  });

  factory AddMemoEntity.fromJson(Map<String, dynamic> json) => AddMemoEntity(
        title: json['title'],
        author: json['author'],
        content: json['content'],
        madeDateTime: json['madeDateTime'],
        modifiedDateTime: json['modifiedDateTime'],
      );

  AddMemoEntity copyWith({
    String? title,
    String? author,
    String? content,
    String? madeDateTime,
    String? modifiedDateTime,
  }) =>
      AddMemoEntity(
        title: title ?? this.title,
        author: author ?? this.author,
        content: content ?? this.content,
        madeDateTime: madeDateTime ?? this.madeDateTime,
        modifiedDateTime: modifiedDateTime ?? this.modifiedDateTime,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'author': author,
        'content': content,
        'madeDateTime': madeDateTime,
        'modifiedDateTime': modifiedDateTime,
      };
}
