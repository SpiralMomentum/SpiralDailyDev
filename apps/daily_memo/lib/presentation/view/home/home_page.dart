import 'package:apps.daily_memo/core/route/app_routes.dart';
import 'package:apps.daily_memo/domain/bloc/home/home_bloc.dart';
import 'package:apps.daily_memo/domain/bloc/home/home_event.dart';
import 'package:apps.daily_memo/domain/bloc/home/home_state.dart';
import 'package:apps.daily_memo/domain/bloc/memo/memo_bloc.dart';
import 'package:apps.daily_memo/domain/bloc/memo/memo_event.dart';
import 'package:apps.daily_memo/domain/bloc/memo/memo_state.dart';
import 'package:apps.daily_memo/presentation/view/app_bar/custom_app_bar.dart';
import 'package:apps.daily_memo/presentation/view/calendar/calendar_page.dart';
import 'package:apps.daily_memo/presentation/view/memo/memo_list_page.dart';
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
                    return CustomAppBar(
                      appBarItems: [
                        CustomAppBarItem(
                          leadingText: "추가",
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
    return NavigationBar(
        onDestinationSelected: (int index) =>
            context.read<HomeBloc>().add(MoveTab(index)),
        indicatorColor: Colors.amber,
        selectedIndex: context.read<HomeBloc>().state.index,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge(child: Icon(Icons.notifications_sharp)),
            label: 'Notifications',
          ),
        ]);
  }
}
