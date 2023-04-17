import 'package:apps.daily_memo/presentation/core/route/routes_impl/app_routes_go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, widget) {
      final state = ref.watch(bottomBarViewModelProvider);
      return state.maybeWhen(
        init: (content) => _buildBottomNavigation(content, ref),
        success: (content) => _buildBottomNavigation(content, ref),
        orElse: () => const CircularProgressIndicator(),
      );
    });
  }

  _buildBottomNavigation(int index, WidgetRef ref) {
    return BottomNavigationBar(
      items: ref.watch(bottomBarViewModelProvider.notifier).navigationItems,
      currentIndex: index,
      onTap: (tappedIndex) {
        if (tappedIndex == index) return;
        ref
            .watch(bottomBarViewModelProvider.notifier)
            .navigationItemOnTap(tappedIndex);
      },
    );
  }
}
