import 'package:uuid/uuid.dart';

class AppConstants {
  // Currency
  static const defaultCurrency = 'USD';
  static const supportedCurrencies = [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'AUD',
    'CAD',
    'CHF',
    'CNY',
    'SEK',
    'NZD',
    'MXN',
    'SGD',
    'HKD',
    'NOK',
    'KRW',
    'TRY',
    'RUB',
    'INR',
    'BRL',
    'ZAR',
    'IDR',
    'MYR',
    'THB',
    'PKR',
    'BGN',
    'HRK',
    'CZK',
    'DKK',
    'HUF',
    'PLN',
    'RON',
    'AED',
    'SAR',
    'QAR',
    'KWD',
    'BHD',
    'OMR',
    'JOD',
    'ILS',
    'EGP',
    'CLP',
    'COP',
    'PEN',
    'ARS',
    'VEF',
    'PHP',
    'VND',
    'BDT',
    'LKR',
    'KES',
    'NGN',
    'GHS',
    'MAD',
    'TND',
    'ANG',
    'BBD',
    'BMD',
    'BSD',
    'BZD',
    'DOP',
    'JMD',
    'TTD',
    'XCD',
    'FJD',
    'PGK',
    'SBD',
    'TOP',
    'WST',
  ];

  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'AUD': 'A\$',
    'CAD': 'C\$',
    'CHF': 'CHF',
    'CNY': '¥',
    'SEK': 'kr',
    'NZD': 'NZ\$',
    'MXN': '\$',
    'SGD': 'S\$',
    'HKD': 'HK\$',
    'NOK': 'kr',
    'KRW': '₩',
    'TRY': '₺',
    'RUB': '₽',
    'INR': '₹',
    'BRL': 'R\$',
    'ZAR': 'R',
    'IDR': 'Rp',
    'MYR': 'RM',
    'THB': '฿',
    'PKR': '₨',
    'BGN': 'лв',
    'HRK': 'kn',
    'CZK': 'Kč',
    'DKK': 'kr',
    'HUF': 'Ft',
    'PLN': 'zł',
    'RON': 'lei',
    'AED': 'د.إ',
    'SAR': '﷼',
    'QAR': '﷼',
    'KWD': 'د.ك',
    'BHD': '.د.ب',
    'OMR': '﷼',
    'JOD': 'د.ا',
    'ILS': '₪',
    'EGP': '£',
    'CLP': '\$',
    'COP': '\$',
    'PEN': 'S/.',
    'ARS': '\$',
    'VEF': 'Bs.',
    'PHP': '₱',
    'VND': '₫',
    'BDT': '৳',
    'LKR': 'Rs',
    'KES': 'Sh',
    'NGN': '₦',
    'GHS': 'GH₵',
    'MAD': 'د.م.',
    'TND': 'د.ت',
    'ANG': 'ƒ',
    'BBD': 'Bds\$',
    'BMD': '\$',
    'BSD': 'B\$',
    'BZD': 'BZ\$',
    'DOP': 'RD\$',
    'JMD': 'J\$',
    'TTD': 'TT\$',
    'XCD': '\$',
    'FJD': 'FJ\$',
    'PGK': 'K',
    'SBD': 'Si\$',
    'TOP': 'T\$',
    'WST': 'T',
  };

  // Payment methods
  static const paymentMethods = [
    'Cash',
    'Credit Card',
    'Debit Card',
    'Bank Transfer',
    'UPI',
    'Mobile Wallet',
    'Cheque',
    'Other'
  ];

  // Recurring frequencies
  static const recurringFrequencies = [
    'Daily',
    'Weekly',
    'Bi-weekly',
    'Monthly',
    'Quarterly',
    'Yearly'
  ];

  // Investment types
  static const investmentTypes = [
    'Stock',
    'Mutual Fund',
    'Cryptocurrency',
    'Gold',
    'ETF',
    'Bonds',
    'Real Estate',
    'Other'
  ];

  // Goal categories
  static const goalCategories = [
    'Savings',
    'Travel',
    'Education',
    'Home',
    'Vehicle',
    'Retirement',
    'Emergency Fund',
    'Other'
  ];
}

class AppUtils {
  static String generateId() {
    return const Uuid().v4();
  }

  static String formatCurrency(double amount,
      {String currencySymbol = '\$', int decimals = 2}) {
    if (amount.isNaN || amount.isInfinite) return '$currencySymbol 0.00';
    return '$currencySymbol ${amount.toStringAsFixed(decimals)}';
  }

  static String currencySymbolForCode(String code) {
    return AppConstants.currencySymbols[code] ?? code;
  }

  static String formatNumber(double number, {int decimals = 2}) {
    if (number.isNaN || number.isInfinite) return '0.00';

    if (number.abs() >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(decimals)}M';
    } else if (number.abs() >= 1000) {
      return '${(number / 1000).toStringAsFixed(decimals)}K';
    }

    return number.toStringAsFixed(decimals);
  }

  static String formatPercentage(double value, {int decimals = 2}) {
    if (value.isNaN || value.isInfinite) return '0.00%';
    return '${value.toStringAsFixed(decimals)}%';
  }

  static String getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }

  static String formatDate(DateTime date) {
    return '${date.day} ${getMonthName(date.month)} ${date.year}';
  }

  static String formatDateShort(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${difference.inDays >= 730 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${difference.inDays >= 60 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays != 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours != 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes != 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  static Map<String, dynamic> calculateMonthPeriod() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    return {
      'start': monthStart,
      'end': monthEnd,
      'month': now.month,
      'year': now.year,
    };
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  static bool isThisYear(DateTime date) {
    return date.year == DateTime.now().year;
  }
}
