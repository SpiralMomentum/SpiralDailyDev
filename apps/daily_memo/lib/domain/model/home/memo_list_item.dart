class MemoListItem {
  final int memoId;
  final String title;
  final String content;
  final String summaryHeaderContent;
  final String summaryFooterContent;
  final String madeDateTime;
  final String modifiedDateTime;

  MemoListItem({
    required this.memoId,
    required this.title,
    required this.content,
    required this.summaryHeaderContent,
    required this.summaryFooterContent,
    required this.madeDateTime,
    required this.modifiedDateTime,
  });
}
