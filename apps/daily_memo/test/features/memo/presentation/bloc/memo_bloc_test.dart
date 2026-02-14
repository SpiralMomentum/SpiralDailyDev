import 'package:app_navigation/app_navigation.dart';
import 'package:apps.daily_memo/features/memo/domain/entities/memo_info_entity.dart';
import 'package:apps.daily_memo/features/memo/domain/usecases/add_memo_use_case.dart';
import 'package:apps.daily_memo/features/memo/domain/usecases/delete_memo_use_case.dart';
import 'package:apps.daily_memo/features/memo/domain/usecases/get_all_memos_use_case.dart';
import 'package:apps.daily_memo/features/memo/domain/usecases/update_memo_use_case.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_bloc.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_event.dart';
import 'package:apps.daily_memo/features/memo/presentation/bloc/memo/memo_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:utils/utils.dart';

class MockGetAllMemosUseCase extends Mock implements GetAllMemosUseCase {}

class MockAddMemoUseCase extends Mock implements AddMemoUseCase {}

class MockUpdateMemoUseCase extends Mock implements UpdateMemoUseCase {}

class MockDeleteMemoUseCase extends Mock implements DeleteMemoUseCase {}

class MockRoutesController extends Mock implements RoutesController {}

void main() {
  late MockGetAllMemosUseCase getAllMemos;
  late MockAddMemoUseCase addMemo;
  late MockUpdateMemoUseCase updateMemo;
  late MockDeleteMemoUseCase deleteMemo;
  late MockRoutesController routesController;

  setUp(() {
    getAllMemos = MockGetAllMemosUseCase();
    addMemo = MockAddMemoUseCase();
    updateMemo = MockUpdateMemoUseCase();
    deleteMemo = MockDeleteMemoUseCase();
    routesController = MockRoutesController();
  });

  MemoBloc buildBloc() => MemoBloc(
        getAllMemosUseCase: getAllMemos,
        addMemoUseCase: addMemo,
        updateMemoUseCase: updateMemo,
        deleteMemoUseCase: deleteMemo,
        routesController: routesController,
      );

  final memos = [
    MemoInfoEntity(
      uniqueId: 1,
      calendarDateTime: DateTime(2025, 1, 1),
      memoMadeDateTime: DateTime(2025, 1, 1, 10, 30),
      memoModifiedDateTime: DateTime(2025, 1, 1, 10, 30),
      title: 'Test',
      content: 'Content',
    ),
  ];

  group('GetAllMemos', () {
    blocTest<MemoBloc, MemoState>(
      'emits [loading, getAllMemosSuccess] when successful',
      build: () {
        when(() => getAllMemos.call())
            .thenAnswer((_) async => Success(memos));
        return buildBloc();
      },
      act: (bloc) => bloc.add(GetAllMemos()),
      expect: () => [
        const MemoState(status: MemoStatus.loading),
        MemoState(status: MemoStatus.getAllMemosSuccess, memos: memos),
      ],
    );

    blocTest<MemoBloc, MemoState>(
      'emits [loading, failure] when usecase fails',
      build: () {
        when(() => getAllMemos.call()).thenAnswer(
          (_) async => const ErrorResult(
              LocalStorageFailure(message: 'error')),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(GetAllMemos()),
      expect: () => [
        const MemoState(status: MemoStatus.loading),
        const MemoState(status: MemoStatus.failure),
      ],
    );
  });

  group('AddMemo', () {
    blocTest<MemoBloc, MemoState>(
      'emits [loading, addMemoSuccess] when successful',
      build: () {
        when(() => addMemo.call(
                title: any(named: 'title'),
                content: any(named: 'content')))
            .thenAnswer((_) async => const Success(true));
        return buildBloc();
      },
      act: (bloc) => bloc.add(AddMemo('New Title', 'New Desc')),
      expect: () => [
        const MemoState(status: MemoStatus.loading),
        const MemoState(status: MemoStatus.addMemoSuccess),
      ],
    );

    blocTest<MemoBloc, MemoState>(
      'emits [loading, failure] when usecase fails',
      build: () {
        when(() => addMemo.call(
                title: any(named: 'title'),
                content: any(named: 'content')))
            .thenAnswer(
          (_) async => const ErrorResult(
              LocalStorageFailure(message: 'error')),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(AddMemo('T', 'D')),
      expect: () => [
        const MemoState(status: MemoStatus.loading),
        const MemoState(status: MemoStatus.failure),
      ],
    );

    blocTest<MemoBloc, MemoState>(
      'uses space for null title and empty string for null desc',
      build: () {
        when(() => addMemo.call(
                title: any(named: 'title'),
                content: any(named: 'content')))
            .thenAnswer((_) async => const Success(true));
        return buildBloc();
      },
      act: (bloc) => bloc.add(AddMemo(null, null)),
      verify: (_) {
        verify(() => addMemo.call(title: ' ', content: '')).called(1);
      },
    );
  });

  group('RemoveMemo', () {
    blocTest<MemoBloc, MemoState>(
      'emits [loading, removeMemoSuccess] when successful',
      build: () {
        when(() => deleteMemo.call(any()))
            .thenAnswer((_) async => const Success(true));
        return buildBloc();
      },
      act: (bloc) => bloc.add(RemoveMemo(1)),
      expect: () => [
        const MemoState(status: MemoStatus.loading),
        const MemoState(status: MemoStatus.removeMemoSuccess),
      ],
    );

    blocTest<MemoBloc, MemoState>(
      'emits [loading, failure] when delete fails',
      build: () {
        when(() => deleteMemo.call(any())).thenAnswer(
          (_) async => const ErrorResult(
              LocalStorageFailure(message: 'error')),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(RemoveMemo(1)),
      expect: () => [
        const MemoState(status: MemoStatus.loading),
        const MemoState(status: MemoStatus.failure),
      ],
    );
  });

  group('UpdateMemo', () {
    blocTest<MemoBloc, MemoState>(
      'emits [loading, updateMemoSuccess] when successful',
      build: () {
        when(() => updateMemo.call(
              memoId: any(named: 'memoId'),
              title: any(named: 'title'),
              content: any(named: 'content'),
              madeDateTime: any(named: 'madeDateTime'),
            )).thenAnswer((_) async => const Success(true));
        return buildBloc();
      },
      act: (bloc) => bloc.add(UpdateMemo(1, 'Updated', 'Updated Desc')),
      expect: () => [
        const MemoState(status: MemoStatus.loading),
        const MemoState(status: MemoStatus.updateMemoSuccess),
      ],
    );
  });
}
