import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ui_components/card/info.dart';
import 'package:ui_components/card/tab_card.dart';

class TimeTabCard extends StatefulWidget {
  final String title;
  final List<Info> infoList;
  final Color backgroundColor;
  final Color indicatorColor;
  final List<Tab> tabs;
  final DateFormat dateFormat;

  const TimeTabCard(
      {super.key,
      required this.title,
      required this.infoList,
      required this.tabs,
      required this.dateFormat,
      required this.backgroundColor,
      required this.indicatorColor})
      : assert(tabs.length == 3);

  @override
  State<StatefulWidget> createState() => _TimeTabCardState();
}

class _TimeTabCardState extends State<TimeTabCard>
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
                TabCard(
                  infoList: widget.infoList.where((e) =>
                      DateTime.now().isBefore(e.startTime) &&
                      DateTime.now().isBefore(e.endTime)),
                  dateFormat: widget.dateFormat,
                ),
                TabCard(
                  infoList: widget.infoList.where((e) =>
                      e.endTime.isAfter(DateTime.now()) &&
                      e.startTime.isBefore(DateTime.now())),
                  dateFormat: widget.dateFormat,
                ),
                TabCard(
                  infoList: widget.infoList.where((e) =>
                      DateTime.now().isBefore(e.startTime) &&
                      DateTime.now().isAfter(e.endTime)),
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
