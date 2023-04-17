import 'package:apps.daily_memo/domain/model/memo/add_memo_model.dart';
import 'package:apps.daily_memo/domain/repository_interface/memo/memo_repository.dart';
import 'package:apps.daily_memo/domain/usecase/memo/memo_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

class MockMemoRepo extends Mock implements MemoRepository{}

@GenerateMocks(<Type>[MockMemoRepo])
void main (){
  late MemoUsecase sut;
  late MockMemoRepo mockMemoRepo;

  setUp((){
    mockMemoRepo = MockMemoRepo();
    sut = MemoUsecase(memoRepository: mockMemoRepo);
  });

  test('getMemoList', (){
    // given
    // when
    // then
  });
  test('getMemoById', (){
    // given
    // when
    // then
  });
  test('addMemo', () async {
    // given
    // when
    // then
  });
  test('modifyMemo', (){
    // given
    // when
    // then
  });
  test('deleteMemo', (){
    // given
    // when
    // then
  });
}