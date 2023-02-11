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

    return StreamBuilder<MemoListItem?>(
        stream: widget.memoViewModel.existedMemo.distinct(),
        builder: (context, snapshot) {
          final MemoListItem? memoListItem = snapshot.data;
          if (memoListItem != null) {
            titleTextController.text = memoListItem.title;
            contentTextController.text = memoListItem.content;
          }

          return Scaffold(
            appBar: _appBar(context),
            bottomSheet: BottomSheet(
              onClosing: () {},
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () => (memoListItem == null)
                      ? widget.memoViewModel.addMemo(
                          titleTextController.text,
                          contentTextController.text,
                          context,
                        )
                      : widget.memoViewModel.modifyMemo(
                          memoListItem.memoId,
                          titleTextController.text,
                          contentTextController.text,
                          memoListItem.madeDateTime,
                          context,
                        ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      color: Colors.amber,
                      alignment: Alignment.center,
                      height: 56.0,
                      width: double.infinity,
                      child: const Text(
                        "저장",
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 96.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "제목",
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextField(
                        maxLines: null,
                        controller: titleTextController,
                        decoration: const InputDecoration(
                          focusedBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.amber, width: 3.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48.0),
                      const Text(
                        "내용",
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextField(
                        controller: contentTextController,
                        maxLines: null,
                        decoration: const InputDecoration(
                          focusedBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.amber, width: 3.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }

  PreferredSizeWidget _appBar(BuildContext context) => PreferredSize(
        preferredSize: const Size.fromHeight(48.0),
        child: AppBar(
          automaticallyImplyLeading: false,
          title: StreamBuilder<MemoListItem?>(
              stream: widget.memoViewModel.existedMemo,
              builder: (context, snapshot) {
                return Text(
                  (snapshot.hasData && snapshot.data != null) ? "수정" : "추가",
                  style: TextStyle(
                    color: Colors.black,
                  ),
                );
              }),
          backgroundColor: Colors.amber,
        ),
      );
}
