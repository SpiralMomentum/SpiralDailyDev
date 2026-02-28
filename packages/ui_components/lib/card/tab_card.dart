import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ui_components/card/info.dart';

class TabCard extends StatelessWidget {
  final Iterable<Info> infoList;
  final DateFormat dateFormat;

  const TabCard({
    super.key,
    required this.infoList,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ...infoList.map(
          (info) => Semantics(
            label: info.title,
            child: SizedBox(
              width: double.infinity,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Semantics(
                    image: true,
                    label: info.title,
                    child: CachedNetworkImage(
                      width: 150,
                      height: 200,
                      fit: BoxFit.cover,
                      imageUrl: info.thumbnail,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          info.title,
                          overflow: TextOverflow.visible,
                        ),
                        Text(dateFormat.format(info.startTime)),
                        Text(dateFormat.format(info.endTime)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}
