import 'package:flutter/material.dart';

import 'adage_theme.dart';

class AdageQuoteDraft {
  const AdageQuoteDraft({required this.body, required this.reference});

  final String body;
  final String reference;
}

class AddAdagePage extends StatefulWidget {
  const AddAdagePage({super.key});

  @override
  State<AddAdagePage> createState() => _AddAdagePageState();
}

class _AddAdagePageState extends State<AddAdagePage> {
  final _bodyController = TextEditingController();
  final _referenceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _bodyController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final draft = AdageQuoteDraft(
      body: _bodyController.text.trim(),
      reference: _referenceController.text.trim().isEmpty
          ? '- 사용자 작성'
          : _referenceController.text.trim(),
    );

    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('새 격언 추가'),
        backgroundColor: AdageColors.backgroundBottom,
        elevation: 0,
      ),
      backgroundColor: AdageColors.backgroundBottom,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '격언 내용',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AdageColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bodyController,
                  maxLines: 5,
                  minLines: 3,
                  style: const TextStyle(color: AdageColors.textPrimary),
                  decoration: _inputDecoration('에너지를 불어넣을 문장을 입력하세요.'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '격언을 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                Text(
                  '출처 (선택)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AdageColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _referenceController,
                  maxLines: 3,
                  minLines: 2,
                  style: const TextStyle(color: AdageColors.textPrimary),
                  decoration: _inputDecoration('명언 출처 혹은 인용구를 입력하세요.'),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AdageColors.accentPrimary,
                      foregroundColor: AdageColors.backgroundBottom,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('저장'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AdageColors.textSecondary),
      filled: true,
      fillColor: AdageColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AdageColors.accentSecondary,
          width: 1.4,
        ),
      ),
    );
  }
}
