import 'package:apps.daily_memo/features/memo/domain/entities/memo_info_entity.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_bloc.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_event.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_state.dart';
import 'package:apps.daily_memo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MemoView extends StatelessWidget {
  final MemoInfoEntity? memoInfo;

  const MemoView({super.key, this.memoInfo});

  bool get isAddMode => memoInfo == null;

  bool get isEditMode => memoInfo != null;

  @override
  Widget build(BuildContext context) {
    TextEditingController titleTextController = TextEditingController();
    TextEditingController contentTextController = TextEditingController();
    if (isEditMode) {
      titleTextController.text = memoInfo!.title;
      contentTextController.text = memoInfo!.content;
    }

    return BlocListener<MemoBloc, MemoState>(
        listener: (context, state) {
          if (state.status == MemoStatus.addMemoSuccess ||
              state.status == MemoStatus.updateMemoSuccess) {
            Navigator.pop(context);
          }
        },
        child: Scaffold(
          appBar: isAddMode ? _addAppBar(context) : _editAppBar(context),
          body: SafeArea(
            child: _buildMemoWidget(
              context,
              titleTextController,
              contentTextController,
            ),
          ),
          bottomSheet: _buildBottomSheet(
            context,
            titleTextController,
            contentTextController,
          ),
        ));
  }

  _buildBottomSheet(
    BuildContext context,
    TextEditingController titleTextController,
    TextEditingController contentTextController,
  ) {
    return BottomSheet(
      onClosing: () {},
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () => BlocProvider.of<MemoBloc>(context)
            ..add(
              isAddMode
                  ? AddMemo(
                      titleTextController.text, contentTextController.text)
                  : UpdateMemo(memoInfo!.uniqueId, titleTextController.text,
                      contentTextController.text),
            ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 48.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.amber,
              ),
              alignment: Alignment.center,
              height: 56.0,
              width: double.infinity,
              child: Text(
                isAddMode
                    ? AppLocalizations.of(context)!.add
                    : AppLocalizations.of(context)!.edit,
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  _buildMemoWidget(
    BuildContext context,
    TextEditingController titleTextController,
    TextEditingController contentTextController,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 96.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.titleLabel,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextField(
              maxLines: null,
              controller: titleTextController,
              decoration: const InputDecoration(
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.amber, width: 3.0),
                ),
              ),
            ),
            const SizedBox(height: 48.0),
            Text(
              l10n.contentLabel,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextField(
              controller: contentTextController,
              maxLines: null,
              decoration: const InputDecoration(
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.amber, width: 3.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _editAppBar(BuildContext context) => PreferredSize(
      preferredSize: const Size.fromHeight(48.0),
      child: AppBar(
        automaticallyImplyLeading: false,
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
        ),
        title: Text(
          AppLocalizations.of(context)!.edit,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.amber,
      ));

  PreferredSizeWidget _addAppBar(BuildContext context) => PreferredSize(
      preferredSize: const Size.fromHeight(48.0),
      child: AppBar(
        automaticallyImplyLeading: false,
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
        ),
        title: Text(
          AppLocalizations.of(context)!.add,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.amber,
      ));
}
