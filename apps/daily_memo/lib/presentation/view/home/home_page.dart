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
        preferredSize: Size.fromHeight(32.0),
        child: AppBar(
          backgroundColor: Colors.amber,
          actions: [
            Row(
              children: [
                IconButton(
                  onPressed: () => homeViewModel.navigateToAddMemo(context),
                  icon: Text("1"),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Text("2"),
                ),
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
                        return HomeListItemView(
                          memoListItem: snapshot.data![index],
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
