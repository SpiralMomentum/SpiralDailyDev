import 'package:apps.daily_memo/features/memo/domain/entities/memo_info_entity.dart';
import 'package:apps.daily_memo/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class MemoListItemView extends StatelessWidget {
  final MemoInfoEntity memoInfo;
  final BehaviorSubject<bool> _isShowFullContent =
      BehaviorSubject.seeded(false);

  MemoListItemView({super.key, required this.memoInfo});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            memoInfo.title.isEmpty ? l10n.emptyTitle : memoInfo.title,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 20.0,
              overflow: TextOverflow.ellipsis,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20.0),
          Text(
            memoInfo.content.isEmpty
                ? l10n.emptyContent
                : (_isShowFullContent.value
                    ? memoInfo.content
                    : memoInfo.content),
            maxLines: 1,
            style: const TextStyle(
              fontSize: 16.0,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16.0),
          Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(l10n.modifiedDate(
                      memoInfo.memoModifiedDateTime.toString())),
                  const SizedBox(height: 2.0),
                  Text(l10n.createdDate(
                      memoInfo.memoMadeDateTime.toString())),
                ],
              )),
        ],
      ),
    );
  }
}
