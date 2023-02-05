import 'package:apps.daily_memo/domain/model/home/memo_list_item.dart';
import 'package:apps.daily_memo/presentation/view_model/memo/memo_viewmodel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MemoView extends StatefulWidget {
  final MemoViewModel memoViewModel;

  const MemoView({super.key, required this.memoViewModel});

  @override
  State<StatefulWidget> createState() => _MemoViewState();
}

class _MemoViewState extends State<MemoView> {
  @override
  Widget build(BuildContext context) {
    TextEditingController titleTextController = TextEditingController();
    TextEditingController contentTextController = TextEditingController();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(32.0),
        child: AppBar(
          title: StreamBuilder<MemoListItem?>(
              stream: widget.memoViewModel.existedMemo,
              builder: (context, snapshot) {
                return Text(
                  (snapshot.hasData && snapshot.data != null) ? "수정" : "추가",
                );
              }),
          backgroundColor: Colors.amber,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: StreamBuilder<MemoListItem?>(
              stream: widget.memoViewModel.existedMemo,
              builder: (context, snapshot) {
                final MemoListItem? memoListItem = snapshot.data;
                if (memoListItem != null) {
                  titleTextController.text = memoListItem.title;
                  contentTextController.text = memoListItem.content;
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      child: Text("제목"),
                    ),
                    TextField(
                      controller: titleTextController,
                    ),
                    Container(
                      child: Text("내용"),
                    ),
                    TextField(
                      controller: contentTextController,
                    ),
                    ElevatedButton(
                      onPressed: () => (memoListItem == null)
                          ? widget.memoViewModel.addMemo(
                              titleTextController.text,
                              contentTextController.text,
                              context,
                            )
                          : widget.memoViewModel.modifyMemo(
                              memoListItem.memoId,
                              titleTextController.text,
                              contentTextController.text,
                              context,
                            ),
                      child: Text("저장"),
                    ),
                  ],
                );
              }),
        ),
      ),
    );
  }
}
