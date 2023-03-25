import 'package:apps.daily_memo/domain/model/home/memo_list_item.dart';
import 'package:apps.daily_memo/presentation/view/bottom_bar/bottom_bar.dart';
import 'package:apps.daily_memo/presentation/view/home/home_list_item_view.dart';
import 'package:apps.daily_memo/presentation/view_model/bottom_bar/bottom_bar_viewmodel.dart';
import 'package:apps.daily_memo/presentation/view_model/home/home_viewmodel.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final HomeViewModel homeViewModel;
  final BottomBar bottomBar;

  const HomePage(
      {super.key,
      required this.homeViewModel,
      required this.bottomBar});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: _homeAppBar(context),
        bottomNavigationBar: bottomBar,
        body: SafeArea(
          child: StreamBuilder<List<MemoListItem>>(
            stream: homeViewModel.getMemos,
            builder: (context, snapshot) {
              final List<MemoListItem>? memoList = snapshot.data;
              return (memoList != null && memoList.isNotEmpty)
                  ? _getMemoListWidget(memoList)
                  : _getDefaultContentWidget();
            },
          ),
        ),
      ),
    );
  }

  Widget _getMemoListWidget(List<MemoListItem> memoItems) {
    return Container(
      color: Colors.white,
      child: ListView.separated(
        itemCount: memoItems.length,
        itemBuilder: (BuildContext context, int index) =>
            _listItem(context, memoItems[index]),
        separatorBuilder: (BuildContext context, int index) => _listDivider,
      ),
    );
  }

  Widget _listItem(BuildContext context, MemoListItem listItem) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => homeViewModel.navigateToModifyMemo(
          context,
          listItem.memoId,
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
                onTap: () => homeViewModel.deleteMemo(
                  listItem.memoId,
                  context,
                ),
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
        child: HomeListItemView(
          memoListItem: listItem,
        ),
      );

  Widget _getDefaultContentWidget() {
    return const Center(
      child: Text(
        "데이터가 없습니다.",
        style: TextStyle(
          fontSize: 28.0,
        ),
      ),
    );
  }

  PreferredSizeWidget _homeAppBar(BuildContext context) => PreferredSize(
        preferredSize: const Size.fromHeight(48.0),
        child: AppBar(
          backgroundColor: Colors.amber,
          automaticallyImplyLeading: false,
          actions: [
            Row(
              children: [
                IconButton(
                  onPressed: () => homeViewModel.navigateToAddMemo(context),
                  icon: const Text(
                    "추가",
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
              ],
            )
          ],
        ),
      );

  Divider get _listDivider => const Divider(
        thickness: 2.0,
        color: Colors.black12,
      );
}
