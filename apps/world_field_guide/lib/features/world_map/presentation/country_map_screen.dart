import 'package:countries_world_map/countries_world_map.dart';
import 'package:flutter/material.dart';

import 'package:world_field_guide/app/theme/app_theme.dart';
import 'package:app_analytics/app_analytics.dart';
import 'package:world_field_guide/features/world_map/domain/usecases/get_country_specialties_use_case.dart';

class CountryMapScreen extends StatefulWidget {
  const CountryMapScreen({
    super.key,
    required this.instruction,
    required this.countryId,
    required this.getCountrySpecialtiesUseCase,
    this.countryName,
    this.analyticsTracker,
  });

  final String instruction;
  final String countryId;
  final String? countryName;
  final GetCountrySpecialtiesUseCase getCountrySpecialtiesUseCase;
  final AnalyticsTracker? analyticsTracker;

  @override
  State<CountryMapScreen> createState() => _CountryMapScreenState();
}

class _CountryMapScreenState extends State<CountryMapScreen> {
  static const double _initialSheetSize = 0.5;
  static const double _minSheetSize = 0.3;
  static const double _maxSheetSize = 0.95;
  static const double _tapDragThreshold = 12;

  late final GetCountrySpecialtiesUseCase _getCountrySpecialtiesUseCase;
  List<String> _specialties = const [];
  bool _isLoading = true;
  bool _hasError = false;

  bool _isBottomSheetOpen = false;
  int? _activePointerId;
  Offset? _initialPointerPosition;
  bool _pointerHasMoved = false;

  @override
  void initState() {
    super.initState();
    _getCountrySpecialtiesUseCase = widget.getCountrySpecialtiesUseCase;

    // 국가 상세 화면 조회 트래킹
    widget.analyticsTracker?.trackScreenView('CountryMapScreen');

    _loadSpecialties().whenComplete(() {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showCountryBottomSheet();
      });
    });
  }

  Future<void> _loadSpecialties() async {
    final result = await _getCountrySpecialtiesUseCase(widget.countryId);
    if (!mounted) return;
    result.when(
      success: (data) {
        setState(() {
          _specialties = data;
          _hasError = false;
          _isLoading = false;
        });
      },
      error: (_) {
        setState(() {
          _specialties = const [];
          _hasError = true;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _showCountryBottomSheet() async {
    if (_isBottomSheetOpen) {
      return;
    }

    setState(() {
      _isBottomSheetOpen = true;
    });

    final draggableController = DraggableScrollableController();

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return DraggableScrollableSheet(
            controller: draggableController,
            expand: false,
            initialChildSize: _initialSheetSize,
            minChildSize: _minSheetSize,
            maxChildSize: _maxSheetSize,
            builder: (context, scrollController) {
              final theme = Theme.of(context);
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x330B3F6A),
                      blurRadius: 24,
                      offset: Offset(0, -8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (draggableController.isAttached) {
                          draggableController.animateTo(
                            _maxSheetSize,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: AppTheme.paleSky,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x190B3F6A),
                                    blurRadius: 16,
                                    offset: Offset(0, 8),
                                  )
                                ],
                              ),
                              child: const Icon(
                                Icons.public,
                                color: AppTheme.primaryBlue,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${widget.countryName ?? widget.countryId.toUpperCase()} 현지 특산품',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.deepNavy,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '현지 특산품 정보를 확인해 보세요.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFE1ECFA),
                    ),
                    Expanded(
                      child: _buildBottomSheetContent(
                        scrollController: scrollController,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBottomSheetOpen = false;
      });
    }
    _resetPointerTracking();
  }

  void _resetPointerTracking() {
    _activePointerId = null;
    _initialPointerPosition = null;
    _pointerHasMoved = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          _activePointerId = event.pointer;
          _initialPointerPosition = event.position;
          _pointerHasMoved = false;
        },
        onPointerMove: (event) {
          if (_activePointerId == event.pointer &&
              _initialPointerPosition != null &&
              !_pointerHasMoved) {
            final delta = (event.position - _initialPointerPosition!).distance;
            if (delta > _tapDragThreshold) {
              _pointerHasMoved = true;
            }
          }
        },
        onPointerUp: (event) {
          final shouldTrigger =
              event.pointer == _activePointerId &&
              !_pointerHasMoved &&
              !_isBottomSheetOpen &&
              mounted;
          _resetPointerTracking();
          if (shouldTrigger) {
            _showCountryBottomSheet();
          }
        },
        onPointerCancel: (_) {
          _resetPointerTracking();
        },
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 12,
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(160),
                  child: SimpleMap(
                    instructions: widget.instruction,
                    fit: BoxFit.contain,
                    defaultColor: const Color(0xFFFAE4C2),
                    countryBorder: const CountryBorder(
                      color: AppTheme.deepNavy,
                      width: 0.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheetContent({
    required ScrollController scrollController,
  }) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        children: const [Text('데이터를 불러오지 못했습니다.', textAlign: TextAlign.center)],
      );
    }

    if (_specialties.isEmpty) {
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        children: [
          Text(
            '${widget.countryName ?? widget.countryId.toUpperCase()}에 대한 특산품 정보가 없습니다.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return ListView.separated(
      controller: scrollController,
      itemCount: _specialties.length,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemBuilder: (context, index) {
        final item = _specialties[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            item,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.deepNavy,
                ),
          ),
        );
      },
      separatorBuilder: (context, index) =>
          const Divider(
            height: 1,
            indent: 24,
            endIndent: 24,
            color: Color(0xFFE1ECFA),
          ),
    );
  }
}
