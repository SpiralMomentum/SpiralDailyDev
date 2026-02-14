import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spiral_trade_show/features/info_shelf/domain/info_shelf_use_case.dart';
import 'package:spiral_trade_show/features/info_shelf/presentation/info_shelf_cubit.dart';
import 'package:spiral_trade_show/features/info_shelf/presentation/info_shelf_state.dart';
import 'package:ui_components/card/info.dart';
import 'package:utils/utils.dart';

class MockInfoShelfUseCase extends Mock implements InfoShelfUseCase {}

void main() {
  late MockInfoShelfUseCase mockUseCase;

  final testInfoList = [
    Info('title1', 'thumb1', 'place1', 'desc1', DateTime(2024, 1, 1),
        DateTime(2024, 1, 31)),
    Info('title2', 'thumb2', 'place2', 'desc2', DateTime(2024, 2, 1),
        DateTime(2024, 2, 28)),
  ];

  setUp(() {
    mockUseCase = MockInfoShelfUseCase();
  });

  group('InfoShelfCubit', () {
    test('initial state는 InfoShelfStatus.initial이어야 한다', () {
      final cubit = InfoShelfCubit(
        const InfoShelfState(info: []),
        mockUseCase,
      );

      expect(cubit.state.status, InfoShelfStatus.initial);
      expect(cubit.state.info, isEmpty);

      cubit.close();
    });

    group('initialLoadInfoList', () {
      blocTest<InfoShelfCubit, InfoShelfState>(
        'success 응답 시 status가 success로 전이되고 info가 업데이트된다',
        setUp: () {
          when(() => mockUseCase.fetchInfoList(0, 30))
              .thenAnswer((_) async => Success(testInfoList));
        },
        build: () => InfoShelfCubit(
          const InfoShelfState(info: []),
          mockUseCase,
        ),
        act: (cubit) => cubit.initialLoadInfoList(),
        expect: () => [
          InfoShelfState(
            status: InfoShelfStatus.success,
            info: testInfoList,
          ),
        ],
        verify: (_) {
          verify(() => mockUseCase.fetchInfoList(0, 30)).called(1);
        },
      );

      blocTest<InfoShelfCubit, InfoShelfState>(
        'error 응답 시 status가 failure로 전이된다',
        setUp: () {
          when(() => mockUseCase.fetchInfoList(0, 30)).thenAnswer(
            (_) async => const ErrorResult(
              NetworkFailure(message: 'error'),
            ),
          );
        },
        build: () => InfoShelfCubit(
          const InfoShelfState(info: []),
          mockUseCase,
        ),
        act: (cubit) => cubit.initialLoadInfoList(),
        expect: () => [
          const InfoShelfState(
            status: InfoShelfStatus.failure,
            info: [],
          ),
        ],
      );
    });

    group('fetchInfoList', () {
      blocTest<InfoShelfCubit, InfoShelfState>(
        'startIndex, endIndex로 호출하면 success 상태를 emit한다',
        setUp: () {
          when(() => mockUseCase.fetchInfoList(30, 60))
              .thenAnswer((_) async => Success(testInfoList));
        },
        build: () => InfoShelfCubit(
          const InfoShelfState(info: []),
          mockUseCase,
        ),
        act: (cubit) => cubit.fetchInfoList(30, 60),
        expect: () => [
          InfoShelfState(
            status: InfoShelfStatus.success,
            info: testInfoList,
          ),
        ],
        verify: (_) {
          verify(() => mockUseCase.fetchInfoList(30, 60)).called(1);
        },
      );

      blocTest<InfoShelfCubit, InfoShelfState>(
        'error 응답 시 failure 상태를 emit한다',
        setUp: () {
          when(() => mockUseCase.fetchInfoList(30, 60)).thenAnswer(
            (_) async => const ErrorResult(
              NetworkFailure(message: 'network error'),
            ),
          );
        },
        build: () => InfoShelfCubit(
          const InfoShelfState(info: []),
          mockUseCase,
        ),
        act: (cubit) => cubit.fetchInfoList(30, 60),
        expect: () => [
          const InfoShelfState(
            status: InfoShelfStatus.failure,
            info: [],
          ),
        ],
      );

      blocTest<InfoShelfCubit, InfoShelfState>(
        'initialLoadInfoList 후 fetchInfoList 호출 시 새로운 info로 대체된다',
        setUp: () {
          final secondList = [
            Info('title3', 'thumb3', 'place3', 'desc3', DateTime(2024, 3, 1),
                DateTime(2024, 3, 31)),
          ];
          when(() => mockUseCase.fetchInfoList(0, 30))
              .thenAnswer((_) async => Success(testInfoList));
          when(() => mockUseCase.fetchInfoList(30, 60))
              .thenAnswer((_) async => Success(secondList));
        },
        build: () => InfoShelfCubit(
          const InfoShelfState(info: []),
          mockUseCase,
        ),
        act: (cubit) async {
          await cubit.initialLoadInfoList();
          await cubit.fetchInfoList(30, 60);
        },
        expect: () => [
          isA<InfoShelfState>()
              .having((s) => s.status, 'status', InfoShelfStatus.success)
              .having((s) => s.info.length, 'info length', 2)
              .having((s) => s.info[0].title, 'first title', 'title1'),
          isA<InfoShelfState>()
              .having((s) => s.status, 'status', InfoShelfStatus.success)
              .having((s) => s.info.length, 'info length', 1)
              .having((s) => s.info[0].title, 'first title', 'title3'),
        ],
        verify: (_) {
          verify(() => mockUseCase.fetchInfoList(0, 30)).called(1);
          verify(() => mockUseCase.fetchInfoList(30, 60)).called(1);
        },
      );
    });
  });
}
