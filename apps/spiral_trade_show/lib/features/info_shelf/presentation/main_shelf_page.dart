import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spiral_trade_show/features/info_shelf/presentation/info_shelf_cubit.dart';
import 'package:ui_components/card/detail_card.dart';
import 'package:ui_components/card/horizon_card.dart';
import 'package:ui_components/card/time_tab_card.dart';
import 'info_shelf_state.dart';
import 'package:intl/intl.dart';

class MainShelfPage extends StatelessWidget {
  final String horizonCardSectionTitle;
  final String detailCardSectionTitle;
  final String tabSectionTitle;
  final List<String> tabItemsTitle;
  final InfoShelfCubit infoShelfCubit;

  const MainShelfPage(
      {super.key,
      required this.horizonCardSectionTitle,
      required this.detailCardSectionTitle,
      required this.infoShelfCubit,
      required this.tabSectionTitle,
      required this.tabItemsTitle});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => infoShelfCubit..initialLoadInfoList(),
      child: BlocBuilder<InfoShelfCubit, InfoShelfState>(
        builder: (context, state) {
          if (state.info.isNotEmpty) {
            return ListView.separated(
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return HorizonCard(
                    sectionTitle: Text(horizonCardSectionTitle),
                    infoList: state.info,
                    sectionBackgroundColor: Colors.grey,
                    sectionHeight: MediaQuery.of(context).size.height * 0.5,
                    imageHeight: MediaQuery.of(context).size.height * 0.35,
                    imageWidth: MediaQuery.of(context).size.width * 0.6,
                  );
                } else if (index == 1) {
                  return DetailCard(
                    sectionTitle: detailCardSectionTitle,
                    info: state.info.elementAt(3),
                    primaryColor: Colors.grey.shade500,
                  );
                } else {
                  return TimeTabCard(
                    title: tabSectionTitle,
                    infoList: state.info,
                    backgroundColor: Colors.grey,
                    indicatorColor: Colors.pink,
                    tabs: [
                      ...tabItemsTitle.map((e) => Tab(
                            child: Text(e,
                                style: const TextStyle(color: Colors.black)),
                          ))
                    ],
                    dateFormat: DateFormat("yyyy년 MM월 dd일"),
                  );
                }
              },
              separatorBuilder: (_, __) => const SizedBox(height: 30),
              itemCount: 3,
            );
          } else {
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
