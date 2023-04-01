// import 'package:apps.daily_memo/domain/model/home/memo_info.dart';
// import 'package:apps.daily_memo/domain/model/memo/memo_list_item.dart';
// import 'package:apps.daily_memo/presentation/view_model/memo/memo_viewmodel.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
//
// class MemoView extends StatefulWidget {
//   final MemoViewModel memoViewModel;
//
//   const MemoView({super.key, required this.memoViewModel});
//
//   @override
//   State<StatefulWidget> createState() => _MemoViewState();
// }
//
// class _MemoViewState extends State<MemoView> {
//   @override
//   Widget build(BuildContext context) {
//     TextEditingController titleTextController = TextEditingController();
//     TextEditingController contentTextController = TextEditingController();
//
//     return StreamBuilder<MemoInfo?>(
//         stream: widget.memoViewModel.existedMemo.distinct(),
//         builder: (context, snapshot) {
//           final MemoInfo? memoListItem = snapshot.data;
//           if (memoListItem != null) {
//             titleTextController.text = memoListItem.title;
//             contentTextController.text = memoListItem.content;
//           }
//
//           return Scaffold(
//             appBar: _appBar(context),
//             bottomSheet: BottomSheet(
//               onClosing: () {},
//               builder: (BuildContext context) {
//                 return GestureDetector(
//                   onTap: () => (memoListItem == null)
//                       ? widget.memoViewModel.addMemo(
//                           titleTextController.text,
//                           contentTextController.text,
//                           context,
//                         )
//                       : widget.memoViewModel.modifyMemo(
//                           memoListItem.uniqueId,
//                           titleTextController.text,
//                           contentTextController.text,
//                           memoListItem.memoMadeDateTime.toString(),
//                           context,
//                         ),
//                   child: Padding(
//                     padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 48.0),
//                     child: Container(
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(8.0),
//                         color: Colors.amber,
//                       ),
//                       alignment: Alignment.center,
//                       height: 56.0,
//                       width: double.infinity,
//                       child: const Text(
//                         "저장",
//                         style: TextStyle(
//                           fontSize: 18.0,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//             body: SafeArea(
//               child: SingleChildScrollView(
//                 child: Container(
//                   padding: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 96.0),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         "제목",
//                         style: TextStyle(
//                           fontSize: 18.0,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       TextField(
//                         maxLines: null,
//                         controller: titleTextController,
//                         decoration: const InputDecoration(
//                           focusedBorder: UnderlineInputBorder(
//                             borderSide:
//                                 BorderSide(color: Colors.amber, width: 3.0),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 48.0),
//                       const Text(
//                         "내용",
//                         style: TextStyle(
//                           fontSize: 18.0,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       TextField(
//                         controller: contentTextController,
//                         maxLines: null,
//                         decoration: const InputDecoration(
//                           focusedBorder: UnderlineInputBorder(
//                             borderSide:
//                                 BorderSide(color: Colors.amber, width: 3.0),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           );
//         });
//   }
//
//
// }

import 'package:apps.daily_memo/domain/model/home/memo_info.dart';
import 'package:apps.daily_memo/presentation/core/route/app_routes.dart';
import 'package:apps.daily_memo/presentation/core/route/routes_controller.dart';
import 'package:apps.daily_memo/presentation/core/route/routes_controller_impl/routes_controller_go_router_impl.dart';
import 'package:apps.daily_memo/presentation/core/route/routes_impl/app_routes_go_router.dart';
import 'package:apps.daily_memo/presentation/view_model/memo/memo_viewmodel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemoView extends ConsumerStatefulWidget {
  final int? memoId;

  MemoView(this.memoId);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MemoViewState();
}

class _MemoViewState extends ConsumerState<MemoView> {
  final RoutesController _routesController = RoutesControllerGoRouterImpl();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ref.read(memoViewModelProvider.notifier).getMemoInfoById(widget.memoId);
    });
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController titleTextController = TextEditingController();
    TextEditingController contentTextController = TextEditingController();

    final state = ref.watch(memoViewModelProvider);

    return Scaffold(
      appBar: state.maybeWhen(
        init: (content) => (content?.values.isEmpty ?? false)
            ? _addAppBar(context)
            : _editAppBar(context),
        orElse: () => _addAppBar(context),
      ),
      body: SafeArea(
        child: state.maybeWhen(
          success: (content) {
            if (content?.values.isNotEmpty ?? false) {
              titleTextController.text = content!.values.first.title;
              contentTextController.text = content.values.first.content;
            }
            return _buildMemoWidget(
              ref,
              titleTextController,
              contentTextController,
            );
          },
          error: (e) => _buildErrorWidget(),
          orElse: () => const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      bottomSheet: state.maybeWhen(
          init: (content) => content?.values.isEmpty ?? false
              ? _buildAddBottomSheet(
                  titleTextController,
                  contentTextController,
                )
              : _buildEditBottomSheet(
                  titleTextController,
                  contentTextController,
                  content!.values.first,
                ),
          success: (content) => content?.values.isEmpty ?? false
              ? _buildAddBottomSheet(
                  titleTextController,
                  contentTextController,
                )
              : _buildEditBottomSheet(
                  titleTextController,
                  contentTextController,
                  content!.values.first,
                ),
          orElse: () => _buildAddBottomSheet(
                titleTextController,
                contentTextController,
              )),
    );
  }

  _buildEditBottomSheet(
    TextEditingController titleTextController,
    TextEditingController contentTextController,
    MemoInfo memoInfo,
  ) {
    return BottomSheet(
      onClosing: () {},
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () => ref.watch(memoViewModelProvider.notifier).modifyMemo(
                memoInfo.uniqueId,
                titleTextController.text,
                contentTextController.text,
                memoInfo.memoMadeDateTime.toString(),
                context,
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
    );
  }

  _buildAddBottomSheet(
    TextEditingController titleTextController,
    TextEditingController contentTextController,
  ) {
    return BottomSheet(
      onClosing: () {},
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () => ref.watch(memoViewModelProvider.notifier).addMemo(
                titleTextController.text,
                contentTextController.text,
                context,
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
              child: const Text(
                "추가",
                style: TextStyle(
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
    WidgetRef ref,
    TextEditingController titleTextController,
    TextEditingController contentTextController,
  ) {
    return SingleChildScrollView(
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
                  borderSide: BorderSide(color: Colors.amber, width: 3.0),
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
                  borderSide: BorderSide(color: Colors.amber, width: 3.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _buildErrorWidget() {
    return AlertDialog(
      title: Text("실패"),
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
          "수정",
          style: TextStyle(
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
          "추가",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.amber,
      ));
}
