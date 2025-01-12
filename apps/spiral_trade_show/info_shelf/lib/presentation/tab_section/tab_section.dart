import 'package:flutter/material.dart';
import 'package:info_shelf/domain/entity/info.dart';
import 'package:info_shelf/presentation/tab_section/tab_item.dart';
import 'package:intl/intl.dart';

class MyTabBarView extends StatefulWidget {
  final String title;
  final List<Info> infoList;
  final Color backgroundColor;
  final Color indicatorColor;
  final List<Tab> tabs;
  final DateFormat dateFormat;

  const MyTabBarView(
      {super.key,
      required this.title,
      required this.infoList,
      required this.tabs,
      required this.dateFormat,
      required this.backgroundColor,
      required this.indicatorColor})
      : assert(tabs.length == 3);

  @override
  State<StatefulWidget> createState() => _MyTabBarViewState();
}

class _MyTabBarViewState extends State<MyTabBarView>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          TabBar(
            controller: _tabController,
            tabs: widget.tabs,
            indicatorColor: widget.indicatorColor,
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4, // 2
            child: TabBarView(
              controller: _tabController,
              children: [
                TabItem(
                  infoList: widget.infoList
                      .where((e) => e.endTime.isBefore(DateTime.now())),
                  dateFormat: widget.dateFormat,
                ),
                TabItem(
                  infoList: widget.infoList.where((e) =>
                      e.endTime.isAfter(DateTime.now()) &&
                      e.startTime.isBefore(DateTime.now())),
                  dateFormat: widget.dateFormat,
                ),
                TabItem(
                  infoList: widget.infoList
                      .where((e) => e.startTime.isAfter(DateTime.now())),
                  dateFormat: widget.dateFormat,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
