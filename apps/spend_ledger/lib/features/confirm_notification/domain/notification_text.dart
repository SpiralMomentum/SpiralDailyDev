import '../../budget/domain/budget_alert.dart';
import '../../budget/domain/summary.dart';
import '../../ledger/domain/money_format.dart';
import '../../ledger/domain/transaction.dart';

/// 확인 알림 카테고리(iOS)·채널(Android) id.
const String confirmCategoryId = 'confirm';

/// 예산 알림 채널 id.
const String budgetChannelId = 'budget';

/// 확인 알림 액션 id. 응답 처리기가 이 값으로 포함/제외를 구분한다.
const String includeActionId = 'include';
const String excludeActionId = 'exclude';

const String includeActionLabel = '포함';
const String excludeActionLabel = '제외';

/// 거래 확인 알림 본문. 음수 금액은 환불 문구.
String confirmBody(Transaction tx) {
  final merchant = tx.counterparty.trim();
  final amount = formatWon(tx.amount.abs());
  if (tx.amount < 0) {
    final prefix = merchant.isEmpty ? '' : '$merchant ';
    return '$prefix환불 $amount을 지출에서 뺄까요?';
  }
  final where = merchant.isEmpty ? '어딘가에서' : '$merchant에서';
  return '$where $amount 지출이 있었던 것 같아요. 지출에 포함할까요?';
}

/// 예산 알림 본문.
String budgetAlertBody(BudgetAlert alert, LedgerSummary s) => switch (alert) {
  BudgetAlert.actualOver =>
    s.budget == null
        ? '이번 달 예산을 넘었어요.'
        : '이번 달 예산 ${formatWon(s.budget!)}을 넘었어요.',
  BudgetAlert.projectedOver => '이대로면 이번 달 예산을 넘을 것 같아요.',
};
