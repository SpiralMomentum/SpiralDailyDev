import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ui_components/card/info.dart';

class DetailCard extends StatelessWidget {
  final String sectionTitle;
  final Color primaryColor;
  final Info info;

  const DetailCard({
    super.key,
    required this.sectionTitle,
    required this.primaryColor,
    required this.info,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 30, 10, 30),
      color: primaryColor,
      child: Column(
        children: [
          Text(
            sectionTitle,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 30),
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: CachedNetworkImage(
              fit: BoxFit.cover,
              width: 200,
              height: 270,
              imageUrl: info.thumbnail,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            info.description,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}
