import 'package:apps.daily_memo/domain/model/home/memo_list_item.dart';
import 'package:apps.daily_memo/domain/repository_interface/memo_repository.dart';
import 'package:apps.daily_memo/domain/usecase/memo_usecase.dart';

class HomeViewModel {
  late final MemoRepository _memoRepository;
  late final MemoUsecase _memoUsecase;

  HomeViewModel({required MemoRepository memoRepository}){
    _memoRepository = memoRepository;
    _memoUsecase = MemoUsecase(_memoRepository);
  }
  /* TODO: bind 공통 ? 비동기
  * 1. 로컬 DB 데이터 불러오기
  * 2. SharedPreference 데이터 불러오기
  * */

  /* TODO: bind 로그인 연동이 되어있을 경우 ? 비동기
  * 1. 서버에서 데이터 불러오기
  *
  */
  Future<List<MemoListItem>> get getMemos => _memoUsecase.getMemoList;
}
