class SavedMemoEntity {
  final int memoId;
  final String? title;
  final String? author;
  final String? content;
  final String? madeDateTime;
  final String? modifiedDateTime;

  SavedMemoEntity({
    required this.memoId,
    this.title,
    this.author,
    this.content,
    this.madeDateTime,
    this.modifiedDateTime,
  });

  factory SavedMemoEntity.fromJson(Map<String, dynamic> json) =>
      SavedMemoEntity(
        memoId: json['memoId'],
        title: json['title'],
        author: json['author'],
        content: json['content'],
        madeDateTime: json['madeDateTime'],
        modifiedDateTime: json['modifiedDateTime'],
      );

  SavedMemoEntity copyWith({
    int? memoId,
    String? title,
    String? author,
    String? content,
    String? madeDateTime,
    String? modifiedDateTime,
  }) =>
      SavedMemoEntity(
        memoId: memoId ?? this.memoId,
        title: title ?? this.title,
        author: author ?? this.author,
        content: content ?? this.content,
        madeDateTime: madeDateTime ?? this.madeDateTime,
        modifiedDateTime: modifiedDateTime ?? this.modifiedDateTime,
      );

  Map<String, dynamic> toJson() =>
      {
        'memoId' : memoId,
        'title': title,
        'author': author,
        'content': content,
        'madeDateTime': madeDateTime,
        'modifiedDateTime': modifiedDateTime,
      };
}
