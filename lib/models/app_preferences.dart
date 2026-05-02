class AppPreferences {
  final String currencyCode;
  final String currencySymbol;
  final String currencyName;
  final String dateFormat;
  final String timeFormat;

  const AppPreferences({
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyName,
    required this.dateFormat,
    required this.timeFormat,
  });

  factory AppPreferences.defaults() {
    return const AppPreferences(
      currencyCode: 'PHP',
      currencySymbol: '₱',
      currencyName: 'Philippine Peso',
      dateFormat: 'MMM dd, yyyy',
      timeFormat: '12h',
    );
  }

  AppPreferences copyWith({
    String? currencyCode,
    String? currencySymbol,
    String? currencyName,
    String? dateFormat,
    String? timeFormat,
  }) {
    return AppPreferences(
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyName: currencyName ?? this.currencyName,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
    );
  }
}