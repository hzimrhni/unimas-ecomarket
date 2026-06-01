String formatRmPrice(
  num? value, {
  bool allowFree = false,
  int decimalPlaces = 2,
}) {
  final price = (value ?? 0).toDouble();
  if (allowFree && price <= 0) {
    return 'Free';
  }
  return 'RM${price.toStringAsFixed(decimalPlaces)}';
}

String formatRmPriceFromDynamic(
  dynamic value, {
  bool allowFree = false,
  int decimalPlaces = 2,
}) {
  final parsed = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
  return formatRmPrice(
    parsed,
    allowFree: allowFree,
    decimalPlaces: decimalPlaces,
  );
}
