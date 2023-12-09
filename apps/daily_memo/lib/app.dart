import 'package:apps.daily_memo/core/route/app_routes.dart';
import 'package:apps.daily_memo/core/route/routes_controller.dart';
import 'package:apps.daily_memo/data/repository_interface/memo/memo_repository.dart';
import 'package:apps.daily_memo/domain/bloc/memo/memo_bloc.dart';
import 'package:apps.daily_memo/domain/bloc/memo/memo_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class App extends StatelessWidget {
  final MemoRepository memoRepository;

  const App({
    super.key,
    required this.memoRepository,
  });

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      routes: AppRoutes.values.map((e) => e.getRouter).toList(),
    );

    // return RepositoryProvider.value(
    //   value: memoRepository,
    //   child: MaterialApp.router(
    //     routeInformationProvider: router.routeInformationProvider,
    //     routeInformationParser: router.routeInformationParser,
    //     routerDelegate: router.routerDelegate,
    //   ),
    // );
    // return BlocProvider<MemoBloc>.value(
    return BlocProvider<MemoBloc>(
      // value: MemoBloc(memoRepository)..add(GetAllMemos()),
      create: (_) => MemoBloc(memoRepository)..add(GetAllMemos()),
      child: MaterialApp.router(
        routeInformationProvider: router.routeInformationProvider,
        routeInformationParser: router.routeInformationParser,
        routerDelegate: router.routerDelegate,
      ),
    );
  }
}
