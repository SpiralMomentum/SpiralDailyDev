class WorldCountryTapDetails {
  const WorldCountryTapDetails({
    required this.countryId,
    required this.instructions,
    this.countryName,
  });

  final String countryId;
  final String? countryName;
  final String instructions;
}

typedef CountryTapCallback = void Function(WorldCountryTapDetails details);
