import 'package:exchange_rate_calculator/domain/model/exchange/exchange_info_model.dart';
import 'package:exchange_rate_calculator/presentation/view_model/home/home_viewmodel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomeView extends StatelessWidget {
  final HomeViewModel homeViewModel = HomeViewModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView.builder(
          itemCount: homeViewModel.enableCountries.length,
          itemBuilder: (context, index) {
            final ExchangeInfoModel exchangeInfo = homeViewModel
                .getExchangeInfo(homeViewModel.enableCountries[index]);
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
          },
        ),
      ),
    );
  }
}
