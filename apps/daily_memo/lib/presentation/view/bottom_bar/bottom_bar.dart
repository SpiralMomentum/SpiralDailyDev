import 'package:apps.daily_memo/presentation/view_model/bottom_bar/bottom_bar_viewmodel.dart';
import 'package:flutter/material.dart';

class BottomBar extends StatelessWidget {
  late final BottomBarViewModel _bottomBarViewModel;

  BottomBar({
    super.key,
    required List<BottomNavigationBarItem> navigationItems,
  }) {
    _bottomBarViewModel = BottomBarViewModel(items: navigationItems);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _bottomBarViewModel.currentIndexStream,
      builder: (context, snapshot) {
        final int? currentIndex = snapshot.data;
        return currentIndex == null
            ? const CircularProgressIndicator()
            : BottomNavigationBar(
                items: _bottomBarViewModel.navigationItems,
                currentIndex: currentIndex,
                onTap: (tappedIndex) {
                  if(tappedIndex == currentIndex) return;
                  _bottomBarViewModel.navigationItemOnTap(tappedIndex, context);
                },
              );
      },
    );
  }
}
