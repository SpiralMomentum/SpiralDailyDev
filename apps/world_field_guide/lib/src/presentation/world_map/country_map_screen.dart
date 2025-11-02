import 'package:countries_world_map/countries_world_map.dart';
import 'package:flutter/material.dart';

import '../../domain/world_local_specialty_repository.dart';
import '../../theme/app_theme.dart';

class CountryMapScreen extends StatefulWidget {
  const CountryMapScreen({
    super.key,
    required this.instruction,
    required this.countryId,
    this.countryName,
  });

  final String instruction;
  final String countryId;
  final String? countryName;

  @override
  State<CountryMapScreen> createState() => _CountryMapScreenState();
}

class _CountryMapScreenState extends State<CountryMapScreen> {
  static const double _initialSheetSize = 0.5;
  static const double _minSheetSize = 0.3;
  static const double _maxSheetSize = 0.95;
  static const double _tapDragThreshold = 12;

  final WorldLocalSpecialtyRepository _specialtyRepository =
      const WorldLocalSpecialtyRepository();
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
    _loadSpecialties().whenComplete(() {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showCountryBottomSheet();
      });
    });
  }

  Future<void> _loadSpecialties() async {
    try {
      final data = await _specialtyRepository.fetchForCountry(widget.countryId);
      if (!mounted) return;
      setState(() {
        _specialties = data;
        _hasError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _specialties = const [];
        _hasError = true;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
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
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 48,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${widget.countryName ?? widget.countryId.toUpperCase()} 현지 특산품',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _buildBottomSheetContent(
                        scrollController: scrollController,
                        draggableController: draggableController,
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
    required DraggableScrollableController draggableController,
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final item = _specialties[index];
        return ListTile(
          title: Text(item),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            if (draggableController.isAttached) {
              draggableController.animateTo(
                _maxSheetSize,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              );
            }
          },
        );
      },
      separatorBuilder: (context, index) =>
          const Divider(height: 1, indent: 16, endIndent: 16),
    );
  }
}
