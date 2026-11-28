import 'package:flutter/material.dart';

import '../../theme/presentation/app_theme.dart';
import '../domain/money_format.dart';
import '../domain/transaction.dart';
import 'tx_labels.dart';

/// 거래 한 줄. 상대·일시·분류와 금액을 보여 준다.
class TxTile extends StatelessWidget {
  const TxTile({super.key, required this.tx, this.onTap, this.trailing});

  final Transaction tx;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final amount = Text(formatWon(tx.amount), style: tabularFigures);
    return ListTile(
      onTap: onTap,
      title: Text(counterpartyLabel(tx)),
      subtitle: Text(
        '${formatWhen(tx.occurredAt)} · ${categoryLabel(tx.category)}'
        ' · ${statusLabel(tx.status)}',
      ),
      trailing: trailing == null
          ? amount
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [amount, const SizedBox(width: 8), trailing!],
            ),
    );
  }
}
