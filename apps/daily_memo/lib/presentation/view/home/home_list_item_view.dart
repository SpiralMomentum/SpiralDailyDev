import 'package:apps.daily_memo/domain/model/home/memo_list_item.dart';
import 'package:flutter/cupertino.dart';

class HomeListItemView extends StatelessWidget {
  final MemoListItem memoListItem;

  const HomeListItemView({super.key, required this.memoListItem});

  @override
  Widget build(BuildContext context) {
    // TODO: 디자인 수정
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(memoListItem.title),
          Text(memoListItem.summaryHeaderContent),
          Text(memoListItem.summaryFooterContent),
          Text(memoListItem.madeDateTime),
        ],
      ),
    );
  }
}
