import 'package:apps.daily_memo/domain/model/home/memo_list_item.dart';
import 'package:apps.daily_memo/presentation/view/home/home_list_item_view.dart';
import 'package:apps.daily_memo/presentation/view_model/home/home_viewmodel.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final HomeViewModel homeViewModel;

  const HomePage({super.key, required this.homeViewModel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(48.0),
        child: AppBar(
          backgroundColor: Colors.amber,
          automaticallyImplyLeading: false,
          actions: [
            Row(
              children: [
                IconButton(
                  onPressed: () => homeViewModel.navigateToAddMemo(context),
                  icon: Text(
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
      ),
      body: SafeArea(
        child: StreamBuilder<List<MemoListItem>>(
          stream: homeViewModel.getMemos,
          builder: (context, snapshot) {
            return (snapshot.hasData && snapshot.data!.isNotEmpty)
                ? Container(
                    color: Colors.white,
                    child: ListView.separated(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (BuildContext context, int index) {
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onLongPress: () => showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              content: Container(
                                child: Text(snapshot.data![index].title.isEmpty
                                    ? "(빈 제목)"
                                    : snapshot.data![index].title),
                              ),
                              actions: [
                                GestureDetector(
                                  onTap: () =>
                                      homeViewModel.navigateToModifyMemo(
                                          context,
                                          snapshot.data![index].memoId),
                                  child: Text("수정하기"),
                                ),
                                const SizedBox(width: 8.0),
                                GestureDetector(
                                  onTap: () => homeViewModel.deleteMemo(
                                      snapshot.data![index].memoId, context),
                                  child: Text("삭제하기"),
                                ),
                              ],
                            ),
                          ),
                          child: HomeListItemView(
                            memoListItem: snapshot.data![index],
                          ),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return const Divider(
                          thickness: 2.0,
                          color: Colors.black12,
                        );
                      },
                    ),
                  )
                : Text("데이터가 없습니다.");
          },
        ),
      ),
    );
  }
}
