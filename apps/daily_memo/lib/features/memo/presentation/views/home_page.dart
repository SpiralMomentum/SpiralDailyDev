import 'package:apps.daily_memo/app/route/app_routes.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/home/home_bloc.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/home/home_event.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/home/home_state.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_bloc.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_event.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_state.dart';
import 'package:apps.daily_memo/features/memo/presentation/views/calendar_page.dart';
import 'package:apps.daily_memo/features/memo/presentation/views/memo_list_page.dart';
import 'package:apps.daily_memo/features/memo/presentation/widgets/custom_app_bar.dart';
import 'package:apps.daily_memo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeView extends StatelessWidget {
  const HomeView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (BuildContext context, state) {
        return WillPopScope(
            onWillPop: () async => false,
            child: Scaffold(
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(48.0),
                child: BlocBuilder<MemoBloc, MemoState>(
                  builder: (context, state) {
                    final l10n = AppLocalizations.of(context)!;
                    final memoBloc = context.read<MemoBloc>();
                    return CustomAppBar(
                      appBarItems: [
                        CustomAppBarItem(
                          leadingText: l10n.add,
                          onTap: () => memoBloc.getRouteController.push(
                            context,
                            AppRoutes.memo.path,
                            extra: {"bloc": memoBloc},
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              body: switch (BlocProvider.of<HomeBloc>(context).state.index) {
                0 => BlocConsumer<MemoBloc, MemoState>(
                    buildWhen: (_, state) =>
                        state.status == MemoStatus.getAllMemosSuccess,
                    builder: (context, state) {
                      return MemoListView(
                        memos: state.memos,
                        routesController: BlocProvider.of<MemoBloc>(context)
                            .getRouteController,
                      );
                    },
                    listenWhen: (_, state) =>
                        state.status == MemoStatus.addMemoSuccess ||
                        state.status == MemoStatus.updateMemoSuccess ||
                        state.status == MemoStatus.removeMemoSuccess,
                    listener: (_, state) {
                      BlocProvider.of<MemoBloc>(context).add(GetAllMemos());
                    },
                  ),
                1 => BlocConsumer<MemoBloc, MemoState>(
                    buildWhen: (_, state) =>
                        state.status == MemoStatus.getAllMemosSuccess,
                    builder: (context, state) {
                      return const CalendarPage();
                    },
                    listenWhen: (_, state) =>
                        state.status == MemoStatus.addMemoSuccess ||
                        state.status == MemoStatus.updateMemoSuccess ||
                        state.status == MemoStatus.removeMemoSuccess,
                    listener: (_, state) {
                      BlocProvider.of<MemoBloc>(context).add(GetAllMemos());
                    },
                  ),
                _ => BlocConsumer<MemoBloc, MemoState>(
                    builder: (context, state) => MemoListView(
                      memos: state.memos,
                      routesController:
                          BlocProvider.of<MemoBloc>(context).getRouteController,
                    ),
                    listenWhen: (_, state) =>
                        state.status == MemoStatus.addMemoSuccess,
                    listener: (_, state) =>
                        BlocProvider.of<MemoBloc>(context).add(GetAllMemos()),
                  ),
              },
              bottomNavigationBar: bottomBar(context),
            ));
      },
    );
  }

  Widget bottomBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return NavigationBar(
        onDestinationSelected: (int index) =>
            context.read<HomeBloc>().add(MoveTab(index)),
        indicatorColor: Colors.amber,
        selectedIndex: context.read<HomeBloc>().state.index,
        destinations: <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home, semanticLabel: l10n.home),
            icon: Icon(Icons.home_outlined, semanticLabel: l10n.home),
            label: l10n.home,
          ),
          NavigationDestination(
            icon: Badge(child: Icon(Icons.notifications_sharp, semanticLabel: l10n.notifications)),
            label: l10n.notifications,
          ),
        ]);
  }
}
