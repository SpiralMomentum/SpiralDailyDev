import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget {
  final List<CustomAppBarItem> appBarItems;

  const CustomAppBar({
    super.key,
    required this.appBarItems,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.amber,
      automaticallyImplyLeading: false,
      actions: [
        Row(
          children: appBarItems.map((CustomAppBarItem item) {
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

class CustomAppBarItem {
  final String leadingText;
  final VoidCallback? onTap;

  CustomAppBarItem({required this.leadingText, required this.onTap});
}
