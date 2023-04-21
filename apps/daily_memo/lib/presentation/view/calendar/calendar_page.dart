import 'package:apps.daily_memo/presentation/core/route/routes_impl/app_routes_go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  @override
  void initState() {
    super.initState();

    ref.read(calendarPageViewModelProvider.notifier).getAllEvents();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calendarPageViewModelProvider);

    return state.maybeWhen(
      success: (content) => TableCalendar(
        headerStyle: const HeaderStyle(
          leftChevronVisible: false,
          rightChevronVisible: false,
          headerPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          formatButtonVisible: false,
        ),
        focusedDay: DateTime.now(),
        firstDay: getFirstDatetime(content.keys.toList()),
        lastDay: DateTime.now(),
        eventLoader: (day) {
          DateTime result =
              DateTime.parse(DateFormat("yyyy-MM-dd").format(day));
          return content[result] ?? [];
        },
        calendarStyle: const CalendarStyle(
          markerSize: 10.0,
          markerDecoration:
              BoxDecoration(color: Colors.red, shape: BoxShape.circle),
        ),
        onFormatChanged: (_){},
      ),
      orElse: () => CircularProgressIndicator(),
    );
  }
  
  DateTime getFirstDatetime(List<DateTime> times){
    if(times.isEmpty) return DateTime.now().subtract(const Duration(days: 31));
    DateTime result = times.first;
    for(DateTime time in times){
      if(result.compareTo(time) < 0){
        result = time;
      }
    }

    return result;
  }

}
