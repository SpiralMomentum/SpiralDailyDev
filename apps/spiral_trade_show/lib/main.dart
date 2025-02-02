import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:spiral_trade_show/common/request_format.dart';
import 'package:spiral_trade_show/common/secure_file.dart';
import 'package:spiral_trade_show/info_shelf/data/info_shelf_repository_impl.dart';
import 'package:spiral_trade_show/info_shelf/domain/info_shelf_cubit.dart';
import 'package:spiral_trade_show/info_shelf/domain/info_shelf_state.dart';
import 'package:spiral_trade_show/info_shelf/domain/info_shelf_use_case.dart';
import 'package:spiral_trade_show/info_shelf/presentation/main_shelf_page.dart';

void main() {
  runApp(
    const TradeShowApp(),
  );
}

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
                        InfoShelfUseCase(
                          InfoShelfRepositoryImpl(
                            Dio(),
                            baseUrl: 'http://openapi.seoul.go.kr:8088',
                            serviceKey: SecureFile.serviceKey,
                            format: RequestFormat.json,
                            serviceName: SecureFile.serviceName,
                          ),
                        ),
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
