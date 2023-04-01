import 'package:apps.daily_memo/domain/model/home/memo_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class MemoListItemView extends StatelessWidget {
  final MemoInfo memoInfo;
  final BehaviorSubject<bool> _isShowFullContent =
      BehaviorSubject.seeded(false);

  MemoListItemView({super.key, required this.memoInfo});

  @override
  Widget build(BuildContext context) {
    // TODO: 디자인 수정
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            memoInfo.title.isEmpty ? "(빈 제목)" : memoInfo.title,
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
                    memoInfo.content.isEmpty
                        ? "(빈 내용)"
                        : (_isShowFullContent.value
                            ? memoInfo.content
                            : memoInfo.content),
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 16.0,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }),
          const SizedBox(height: 16.0),
          Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("수정일 " + memoInfo.memoModifiedDateTime.toString()),
                  const SizedBox(height: 2.0),
                  Text("생성일 " + memoInfo.memoMadeDateTime.toString())
                ],
              )),
        ],
      ),
    );
  }
}
