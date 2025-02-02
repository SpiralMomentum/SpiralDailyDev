import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ui_components/card/info.dart';

class HorizonCard extends StatelessWidget {
  final Text sectionTitle;
  final Color sectionBackgroundColor;
  final List<Info> infoList;
  final double sectionHeight;
  final double imageHeight;
  final double imageWidth;

  const HorizonCard(
      {super.key,
      required this.sectionTitle,
      required this.infoList,
      required this.sectionBackgroundColor,
      required this.sectionHeight,
      required this.imageHeight,
      required this.imageWidth})
      : assert(sectionHeight != 0 &&
            imageHeight != 0 &&
            imageWidth != 0 &&
            sectionHeight > imageHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 30, 10, 30),
      color: sectionBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: sectionTitle,
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: sectionHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  height: imageHeight + 0.1,
                  width: imageWidth + 0.1,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.black12,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 50,
                        child: Text(
                          infoList[index].title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: CachedNetworkImage(
                          fit: BoxFit.cover,
                          height: imageHeight,
                          width: imageWidth,
                          imageUrl: infoList[index].thumbnail,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        infoList[index].place,
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(width: 5),
              itemCount: infoList.length,
            ),
          ),
        ],
      ),
    );
  }
}
