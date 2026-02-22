import 'package:app_analytics/app_analytics.dart';
import 'package:flutter/material.dart';

import 'package:spiral_trade_show/app/di/service_locator.dart';
import 'package:spiral_trade_show/features/info_shelf/domain/info_shelf_use_case.dart';
import 'package:spiral_trade_show/features/info_shelf/presentation/info_shelf_cubit.dart';
import 'package:spiral_trade_show/features/info_shelf/presentation/info_shelf_state.dart';
import 'package:spiral_trade_show/features/info_shelf/presentation/main_shelf_page.dart';

class TradeShowApp extends StatelessWidget {
  const TradeShowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SafeArea(
        child: Scaffold(
          body: SafeArea(
            child: Container(
              color: Colors.black,
              child: Column(
                children: [
                  Expanded(
                    child: MainShelfPage(
                      horizonCardSectionTitle: '금주의 전시',
                      detailCardSectionTitle: '추천 전시',
                      tabSectionTitle: '전시 계획',
                      tabItemsTitle: const ['전시 예정', '전시 중', '전시 종료'],
                      infoShelfCubit: InfoShelfCubit(
                        const InfoShelfState(info: []),
                        getIt<InfoShelfUseCase>(),
                        analyticsTracker: getIt<AnalyticsTracker>(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
