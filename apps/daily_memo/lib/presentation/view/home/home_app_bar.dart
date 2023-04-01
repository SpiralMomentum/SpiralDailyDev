import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomeAppBar extends StatelessWidget {
  final List<HomeAppBarItem> homeAppBarItems;

  const HomeAppBar({
    super.key,
    required this.homeAppBarItems,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.amber,
      automaticallyImplyLeading: false,
      actions: [
        Row(
          children: homeAppBarItems.map((HomeAppBarItem item) {
            return Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: IconButton(
                onPressed: item.onTap,
                icon: Text(
                  item.leadingText,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 16.0,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class HomeAppBarItem {
  final String leadingText;
  final VoidCallback? onTap;

  HomeAppBarItem({
    required this.leadingText,
    this.onTap,
  });
}
