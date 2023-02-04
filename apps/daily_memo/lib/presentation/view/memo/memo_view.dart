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
    if (widget.memoViewModel.isModifiedMemo) {
      titleTextController.text = widget.memoViewModel.beforeTitle;
      contentTextController.text = widget.memoViewModel.beforeContent;
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(32.0),
        child: AppBar(
          title: Text(
            widget.memoViewModel.isAddMemo ? "추가" : "수정",
          ),
          backgroundColor: Colors.amber,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
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
                onPressed: () => widget.memoViewModel.addMemo(
                  titleTextController.text,
                  contentTextController.text,
                  context,
                ),
                child: Text("저장"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
