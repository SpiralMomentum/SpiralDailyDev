import 'package:apps.daily_memo/domain/model/home/memo_info.dart';
import 'package:apps.daily_memo/presentation/core/route/routes_impl/app_routes_go_router.dart';
import 'package:apps.daily_memo/presentation/view/memo/memo_list_item_view.dart';
import 'package:apps.daily_memo/presentation/view_model/memo/memo_list_page_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemoListPage extends ConsumerStatefulWidget {
  const MemoListPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MemoListPageState();
}

class _MemoListPageState extends ConsumerState<MemoListPage> {
  @override
  void initState() {
    super.initState();
    ref.read(memoListPageViewModelProvider.notifier).getMemoList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(memoListPageViewModelProvider);

    return SafeArea(
      child: state.maybeWhen(
        init: (content) => content.values.isEmpty
            ? _getDefaultContentWidget()
            : _getMemoListWidget(
                content.values,
                ref.watch(memoListPageViewModelProvider.notifier),
              ),
        success: (content) => content.values.isEmpty
            ? _getDefaultContentWidget()
            : _getMemoListWidget(
                content.values,
                ref.watch(memoListPageViewModelProvider.notifier),
              ),
        orElse: () => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _getMemoListWidget(
      List<MemoInfo> memoItems, MemoListPageViewModel memoListPageViewModel) {
    return Container(
      color: Colors.white,
      child: ListView.separated(
        itemCount: memoItems.length,
        itemBuilder: (BuildContext context, int index) => _listItem(
          context,
          memoItems[index],
          memoListPageViewModel,
        ),
        separatorBuilder: (BuildContext context, int index) => _listDivider,
      ),
    );
  }

  Widget _listItem(
    BuildContext context,
    MemoInfo listItem,
    MemoListPageViewModel memoListPageViewModel,
  ) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => memoListPageViewModel.navigateToModifyMemo(
          context,
          listItem.uniqueId,
        ),
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
                    listItem.title.isEmpty ? "(빈 제목)" : listItem.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    listItem.content.isEmpty ? "(빈 내용)" : listItem.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                ],
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () =>
                    memoListPageViewModel.deleteMemo(listItem.uniqueId, context),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("삭제하기"),
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

  Widget _getDefaultContentWidget() {
    return const Text(
      "데이터가 없습니다.",
      style: TextStyle(
        fontSize: 28.0,
      ),
    );
  }

  Divider get _listDivider => const Divider(
        thickness: 2.0,
        color: Colors.black12,
      );
}
