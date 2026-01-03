import 'package:apps.daily_memo/features/memo/domain/entities/memo_info_entity.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) => const CalendarView();
}

class CalendarView extends StatelessWidget {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      headerStyle: const HeaderStyle(
        leftChevronVisible: false,
        rightChevronVisible: false,
        headerPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        formatButtonVisible: false,
      ),
      focusedDay: DateTime.now(),
      firstDay: getFirstDatetime(
          temp(BlocProvider.of<MemoBloc>(context).state.memos).keys.toList()),
      lastDay: DateTime.now(),
      eventLoader: (day) {
        final memos = BlocProvider.of<MemoBloc>(context).state.memos;
        DateTime result = DateTime.parse(DateFormat("yyyy-MM-dd").format(day));

        return memos.where((e) => e.calendarDateTime == result).toList() ?? [];
      },
      calendarStyle: const CalendarStyle(
        markerSize: 10.0,
        markerDecoration:
            BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      ),
      onFormatChanged: (_) {},
    );
  }

  DateTime getFirstDatetime(List<DateTime> times) {
    if (times.isEmpty) return DateTime.now().subtract(const Duration(days: 31));
    DateTime result = times.first;
    for (DateTime time in times) {
      if (result.compareTo(time) < 0) {
        result = time;
      }
    }

    return result;
  }

  Map<DateTime, List<MemoInfoEntity>> temp(List<MemoInfoEntity> memos) {
    Map<DateTime, List<MemoInfoEntity>> result = {};
    for (MemoInfoEntity memoInfo in memos) {
      final calendarDateTime = DateTime.parse(
          DateFormat("yyyy-MM-dd").format(memoInfo.memoModifiedDateTime));

      if (result.containsKey(calendarDateTime)) {
        final List<MemoInfoEntity> memos = result[calendarDateTime]!;
        memos.add(memoInfo);
        result[calendarDateTime] = memos;
      } else {
        result[calendarDateTime] = [memoInfo];
      }
    }

    return result;
  }
}
