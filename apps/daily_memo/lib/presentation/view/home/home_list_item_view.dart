import 'package:apps.daily_memo/domain/model/home/memo_list_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class HomeListItemView extends StatelessWidget {
  final MemoListItem memoListItem;
  final BehaviorSubject<bool> _isShowFullContent =
      BehaviorSubject.seeded(false);

  HomeListItemView({super.key, required this.memoListItem});

  @override
  Widget build(BuildContext context) {
    // TODO: 디자인 수정
    return Container(
      height: 96.0,
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            memoListItem.title.isEmpty ? "(빈 제목)" : memoListItem.title,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 20.0,
              overflow: TextOverflow.ellipsis,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20.0),
          StreamBuilder<bool>(
              stream: _isShowFullContent,
              builder: (context, snapshot) {
                return GestureDetector(
                  onTap: () =>
                      _isShowFullContent.add(!_isShowFullContent.value),
                  child: Text(
                    memoListItem.content.isEmpty
                        ? "(빈 내용)"
                        : (_isShowFullContent.value
                            ? memoListItem.content
                            : memoListItem.summaryHeaderContent +
                                memoListItem.summaryFooterContent),
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 16.0,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text("수정일 " + memoListItem.modifiedDateTime),
              const SizedBox(width: 16.0),
              Text("생성일 " + memoListItem.madeDateTime),
            ],
          )
        ],
      ),
    );
  }
}
