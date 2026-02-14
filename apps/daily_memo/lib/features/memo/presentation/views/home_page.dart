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
        final homeBloc = BlocProvider.of<HomeBloc>(context);

        return WillPopScope(
            onWillPop: () async => false,
            child: Scaffold(
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(48.0),
                child: BlocBuilder<MemoBloc, MemoState>(
                  builder: (context, state) {
                    final l10n = AppLocalizations.of(context)!;
                    return CustomAppBar(
                      appBarItems: [
                        CustomAppBarItem(
                          leadingText: l10n.add,
                          onTap: () => homeBloc.add(
                            MoveToAddMemo(
                              context: context,
                              memoBloc: context.read<MemoBloc>(),
                            ),
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
              // body: widgets[0],
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
            selectedIcon: const Icon(Icons.home),
            icon: const Icon(Icons.home_outlined),
            label: l10n.home,
          ),
          NavigationDestination(
            icon: const Badge(child: Icon(Icons.notifications_sharp)),
            label: l10n.notifications,
          ),
        ]);
  }
}
