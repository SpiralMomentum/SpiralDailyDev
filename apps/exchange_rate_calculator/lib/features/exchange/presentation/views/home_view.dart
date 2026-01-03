import 'package:exchange_rate_calculator/features/exchange/domain/entities/exchange_info.dart';
import 'package:exchange_rate_calculator/features/exchange/domain/repositories/exchange_repository.dart';
import 'package:exchange_rate_calculator/features/exchange/presentation/view_models/home_view_model.dart';
import 'package:flutter/material.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        if (widget.viewModel.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final errorMessage = widget.viewModel.errorMessage;
        if (errorMessage != null) {
          return Scaffold(
            body: Center(
              child: Text(
                errorMessage,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: ListView.builder(
              itemCount: widget.viewModel.enableCountries.length,
              itemBuilder: (context, index) {
                final ExchangeCountry country =
                    widget.viewModel.enableCountries[index];
                final result = widget.viewModel.getExchangeInfo(country);
                return result.when(
                  success: (exchangeInfo) => _ExchangeRow(
                    exchangeInfo: exchangeInfo,
                  ),
                  error: (_) => _ExchangeRow(
                    exchangeInfo: ExchangeInfo(
                      countryName: country.name,
                      currentCoinName: country.currentCoinName,
                      exchangeRate: 0.0,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ExchangeRow extends StatelessWidget {
  const _ExchangeRow({required this.exchangeInfo});

  final ExchangeInfo exchangeInfo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            exchangeInfo.countryName,
            style: const TextStyle(
              fontSize: 16.0,
              color: Colors.black,
            ),
          ),
          Text(
            exchangeInfo.currentCoinName,
            style: const TextStyle(
              fontSize: 16.0,
              color: Colors.black,
            ),
          ),
          Text(
            exchangeInfo.exchangeRate.toString(),
            style: const TextStyle(
              fontSize: 16.0,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
