import 'package:apps.daily_memo/domain/model/home/memo_list_item.dart';
import 'package:apps.daily_memo/presentation/core/route/app_routes.dart';
import 'package:apps.daily_memo/presentation/core/route/routes_controller.dart';
import 'package:apps.daily_memo/presentation/core/route/routes_controller_impl/routes_controller_modular_impl.dart';
import 'package:apps.daily_memo/presentation/view/home/home_list_item_view.dart';
import 'package:apps.daily_memo/presentation/view_model/home/home_viewmodel.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final HomeViewModel homeViewModel;

  const HomePage({super.key, required this.homeViewModel});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: _homeAppBar(context),
        body: SafeArea(
          child: StreamBuilder<List<MemoListItem>>(
            stream: homeViewModel.getMemos,
            builder: (context, snapshot) {
              final List<MemoListItem>? memoList = snapshot.data;
              return (memoList != null && memoList.isNotEmpty)
                  ? Container(
                      color: Colors.white,
                      child: ListView.separated(
                        itemCount: memoList.length,
                        itemBuilder: (BuildContext context, int index) =>
                            _listItem(context, memoList[index]),
                        separatorBuilder: (BuildContext context, int index) =>
                            _listDivider,
                      ),
                    )
                  : const Text("데이터가 없습니다.");
            },
          ),
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

  Widget _listItem(BuildContext context, MemoListItem listItem) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () => showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(listItem.title.isEmpty ? "(빈 제목)" : listItem.title),
            actions: [
              GestureDetector(
                onTap: () => homeViewModel.navigateToModifyMemo(
                  context,
                  listItem.memoId,
                ),
              ),
              const SizedBox(width: 8.0),
              GestureDetector(
                onTap: () => homeViewModel.deleteMemo(
                  listItem.memoId,
                  context,
                ),
                child: const Text("삭제하기"),
              ),
            ],
          ),
        ),
        child: HomeListItemView(
          memoListItem: listItem,
        ),
      );

  Divider get _listDivider => const Divider(
        thickness: 2.0,
        color: Colors.black12,
      );
}
