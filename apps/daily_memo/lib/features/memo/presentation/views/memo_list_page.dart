import 'package:app_navigation/app_navigation.dart';
import 'package:apps.daily_memo/app/route/app_routes.dart';
import 'package:apps.daily_memo/features/memo/domain/entities/memo_info_entity.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_bloc.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_event.dart';
import 'package:apps.daily_memo/features/memo/presentation/views/memo_list_item_view.dart';
import 'package:apps.daily_memo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MemoListView extends StatelessWidget {
  final List<MemoInfoEntity> memos;
  final RoutesController routesController;

  const MemoListView({
    super.key,
    required this.memos,
    required this.routesController,
  });

  @override
  Widget build(BuildContext context) {
    return memos.isEmpty
        ? _getDefaultContentWidget(context)
        : _getMemoListWidget(memos);
  }

  Widget _getMemoListWidget(List<MemoInfoEntity> memoItems) {
    return ListView.separated(
      itemCount: memoItems.length,
      itemBuilder: (BuildContext context, int index) => _listItem(
        context,
        memoItems[index],
      ),
      separatorBuilder: (BuildContext context, int index) => _listDivider,
    );
  }

  Widget _listItem(
    BuildContext context,
    MemoInfoEntity listItem,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        MemoInfoEntity? memoInfo;
        try {
          memoInfo = BlocProvider.of<MemoBloc>(context)
              .state
              .memos
              .firstWhere((e) => e.uniqueId == listItem.uniqueId);
        } catch (e) {
          memoInfo = null;
        }

        routesController.push(
          context,
          AppRoutes.memo.path,
          extra: {"memoInfo": memoInfo},
        );
      },
      // .add(GetMemo(listItem.uniqueId)),
      onLongPress: () => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          actionsPadding: const EdgeInsets.all(16.0),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0))),
          content: Container(
            height: 67.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  listItem.title.isEmpty
                      ? AppLocalizations.of(context)!.emptyTitle
                      : listItem.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  listItem.content.isEmpty
                      ? AppLocalizations.of(context)!.emptyContent
                      : listItem.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              ],
            ),
          ),
          actions: [
            GestureDetector(
              onTap: () {
                BlocProvider.of<MemoBloc>(context)
                    .add(RemoveMemo(listItem.uniqueId));
                routesController.pop(context);
              },
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(AppLocalizations.of(context)!.deleteAction),
                ),
              ),
            ),
          ],
        ),
      ),
      child: MemoListItemView(
        memoInfo: listItem,
      ),
    );
  }

  Widget _getDefaultContentWidget(BuildContext context) {
    return Text(
      AppLocalizations.of(context)!.noMemos,
      style: const TextStyle(
        fontSize: 28.0,
      ),
    );
  }

  Divider get _listDivider => const Divider(
        thickness: 2.0,
        color: Colors.black12,
      );
}
