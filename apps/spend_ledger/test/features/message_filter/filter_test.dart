import 'package:flutter_test/flutter_test.dart';
import 'package:spend_ledger/features/message_filter/domain/filter.dart';
import 'package:spend_ledger/features/message_filter/domain/filter_rule.dart';
import 'package:spend_ledger/features/message_filter/domain/name_registry.dart';
import 'package:spend_ledger/features/message_filter/domain/raw_message.dart';

import '../../fixtures/messages.dart';

RawMessage msg(String text, {String? sender}) => RawMessage(
      text: text,
      sender: sender,
      receivedAt: DateTime(2026, 11, 27),
      source: MessageSource.manual,
    );

void main() {
  test('default rules pass approval', () {
    expect(passesFilter(msg(kbApproval), defaultFilterRules), isTrue);
  });

  test('default rules drop deposit', () {
    expect(passesFilter(msg(deposit), defaultFilterRules), isFalse);
  });

  test('default rules drop ad', () {
    expect(passesFilter(msg(ad), defaultFilterRules), isFalse);
  });

  test('amount without keyword passes', () {
    expect(passesFilter(msg(noKeyword), defaultFilterRules), isTrue);
  });

  test('keyword without amount passes', () {
    expect(passesFilter(msg(noAmount), defaultFilterRules), isTrue);
  });

  test('sender-scoped exclude applies only to that sender', () {
    const rules = [
      FilterRule(senderPattern: '1588', excludeKeywords: ['포인트']),
    ];
    const text = '포인트 적립 안내';
    expect(passesFilter(msg(text, sender: '15881688'), rules), isFalse);
    expect(passesFilter(msg(text, sender: '0000'), rules), isTrue);
    expect(passesFilter(msg(text), rules), isTrue);
  });

  test('json roundtrip', () {
    const rule = FilterRule(
      senderPattern: '1588',
      includeKeywords: ['승인'],
      excludeKeywords: ['광고'],
    );
    expect(FilterRule.fromJson(rule.toJson()), rule);
    const names = NameRegistry(
      selfNames: ['홍길동'],
      chargeTargets: ['쿠팡페이'],
      prepaidMoneys: ['쿠페이머니'],
    );
    expect(NameRegistry.fromJson(names.toJson()), names);
    expect(const NameRegistry.empty().selfNames, isEmpty);
  });
}
