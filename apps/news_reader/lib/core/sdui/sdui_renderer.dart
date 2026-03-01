import 'package:flutter/material.dart';

/// JSON 스키마로 피드 카드 타입/순서를 서버에서 제어하는 SDUI 렌더러.
///
/// 서버가 내려주는 widget spec JSON을 Flutter Widget 트리로 변환한다.
/// 지원 타입: article_card, banner_card, category_header, spacer.
class SduiRenderer {
  /// JSON widget spec 하나를 Flutter Widget으로 변환한다.
  ///
  /// [spec]은 `widget_type` 키를 반드시 포함해야 한다.
  /// [data]는 바인딩할 데이터 (예: 기사 제목, 요약 등).
  static Widget render(
    Map<String, dynamic> spec, {
    Map<String, dynamic>? data,
  }) {
    final type = spec['widget_type'] as String?;
    switch (type) {
      case 'article_card':
        return _buildArticleCard(spec, data);
      case 'banner_card':
        return _buildBannerCard(spec, data);
      case 'category_header':
        return _buildCategoryHeader(spec, data);
      case 'spacer':
        return SizedBox(
          height: (spec['height'] as num?)?.toDouble() ?? 16,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// JSON spec 리스트를 Widget 리스트로 변환한다.
  static List<Widget> renderList(
    List<Map<String, dynamic>> specs, {
    Map<String, dynamic>? data,
  }) {
    return specs.map((spec) => render(spec, data: data)).toList();
  }

  // ---------------------------------------------------------------------------
  // Private builders
  // ---------------------------------------------------------------------------

  static Widget _buildArticleCard(
    Map<String, dynamic> spec,
    Map<String, dynamic>? data,
  ) {
    final title = data?['title'] as String? ?? spec['title'] as String? ?? '';
    final summary =
        data?['summary'] as String? ?? spec['summary'] as String? ?? '';
    final imageUrl = data?['image_url'] as String? ??
        spec['image_url'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image, size: 48),
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.image, size: 48),
                    ),
            ),
            const SizedBox(height: 12),
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (summary.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                summary,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _buildBannerCard(
    Map<String, dynamic> spec,
    Map<String, dynamic>? data,
  ) {
    final text = spec['text'] as String? ?? '';
    final colorHex = spec['color'] as String?;
    final textColorHex = spec['text_color'] as String?;
    final height = (spec['height'] as num?)?.toDouble() ?? 120;

    final bgColor = _parseColor(colorHex) ?? Colors.blue;
    final textColor = _parseColor(textColorHex) ?? Colors.white;

    return Container(
      height: height,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  static Widget _buildCategoryHeader(
    Map<String, dynamic> spec,
    Map<String, dynamic>? data,
  ) {
    final label = spec['label'] as String? ?? '';
    final fontSize = (spec['font_size'] as num?)?.toDouble() ?? 22;
    final colorHex = spec['color'] as String?;
    final color = _parseColor(colorHex) ?? Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// '#RRGGBB' 또는 '#AARRGGBB' 형식 문자열을 [Color]로 변환한다.
  static Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var cleaned = hex.replaceFirst('#', '');
    if (cleaned.length == 6) {
      cleaned = 'FF$cleaned';
    }
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return null;
    return Color(value);
  }
}
