import 'package:flutter/material.dart';

import 'package:apps.news_reader/features/news_feed/domain/entities/article.dart';
import 'package:apps.news_reader/features/settings/domain/repositories/settings_repository.dart';
import '../widgets/category_selector.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.settingsRepository,
    required this.onCompleted,
  });

  final SettingsRepository settingsRepository;
  final VoidCallback onCompleted;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<ArticleCategory> _selectedCategories = [];
  bool _notificationsAccepted = false;

  static const int _totalPages = 3;
  static const int _minimumCategories = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _canProceed {
    if (_currentPage == 1) {
      return _selectedCategories.length >= _minimumCategories;
    }
    return true;
  }

  Future<void> _onNextOrComplete() async {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await widget.settingsRepository.setOnboardingCompleted(true);
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildIntroPage(context),
                  _buildCategoryPage(context),
                  _buildNotificationPage(context),
                ],
              ),
            ),
            _buildBottomSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroPage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.newspaper,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'News Reader',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 16),
          Text(
            'Stay informed with personalized news from around the world. '
            'Choose your interests and get the stories that matter to you.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Choose Your Interests',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll personalize your feed based on your selections.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          CategorySelector(
            selectedCategories: _selectedCategories,
            onChanged: (categories) {
              setState(() {
                _selectedCategories = categories;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Stay Updated',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Enable notifications to get breaking news alerts '
            'and updates on topics you care about.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: _notificationsAccepted,
            onChanged: (value) {
              setState(() {
                _notificationsAccepted = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalPages, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _currentPage == index
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _canProceed ? _onNextOrComplete : null,
              child: Text(
                _currentPage == _totalPages - 1 ? '\uc2dc\uc791\ud558\uae30' : '\ub2e4\uc74c',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
