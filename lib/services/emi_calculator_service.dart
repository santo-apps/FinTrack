import 'dart:math';

class EMICalculator {
  /// Calculate EMI (Equated Monthly Installment)
  /// Formula: EMI = [P * R * (1 + R)^N] / [(1 + R)^N - 1]
  /// P = Principal, R = Monthly Rate, N = Number of months
  static double calculateEMI({
    required double principalAmount,
    required double annualInterestRate,
    required int tenureMonths,
  }) {
    if (principalAmount <= 0 || annualInterestRate < 0 || tenureMonths <= 0) {
      return 0;
    }

    final monthlyRate = annualInterestRate / 12 / 100;
    if (monthlyRate == 0) {
      return principalAmount / tenureMonths;
    }

    final numerator =
        principalAmount * monthlyRate * pow(1 + monthlyRate, tenureMonths);
    final denominator = pow(1 + monthlyRate, tenureMonths) - 1;
    return (numerator / denominator).toDouble();
  }

  /// Generate amortization schedule
  static List<AmortizationEntry> generateAmortizationSchedule({
    required double principalAmount,
    required double annualInterestRate,
    required int tenureMonths,
  }) {
    final schedule = <AmortizationEntry>[];
    final emi = calculateEMI(
      principalAmount: principalAmount,
      annualInterestRate: annualInterestRate,
      tenureMonths: tenureMonths,
    );

    double remainingBalance = principalAmount;
    final monthlyRate = annualInterestRate / 12 / 100;

    for (int month = 1; month <= tenureMonths; month++) {
      final interestAmount = remainingBalance * monthlyRate;
      final principalComponent = emi - interestAmount;
      remainingBalance = max(0, remainingBalance - principalComponent);

      schedule.add(
        AmortizationEntry(
          monthNumber: month,
          emi: emi,
          principalComponent: principalComponent,
          interestComponent: interestAmount,
          remainingBalance: remainingBalance,
        ),
      );
    }

    return schedule;
  }

  /// Calculate total interest amount
  static double calculateTotalInterest({
    required double principalAmount,
    required double annualInterestRate,
    required int tenureMonths,
  }) {
    final emi = calculateEMI(
      principalAmount: principalAmount,
      annualInterestRate: annualInterestRate,
      tenureMonths: tenureMonths,
    );
    return (emi * tenureMonths) - principalAmount;
  }

  /// Calculate remaining balance after N months of payment
  static double getRemainingBalance({
    required double principalAmount,
    required double annualInterestRate,
    required int tenureMonths,
    required int monthsPaid,
  }) {
    final schedule = generateAmortizationSchedule(
      principalAmount: principalAmount,
      annualInterestRate: annualInterestRate,
      tenureMonths: tenureMonths,
    );

    if (monthsPaid <= 0 || monthsPaid > schedule.length) {
      return monthsPaid <= 0 ? principalAmount : 0;
    }

    return schedule[monthsPaid - 1].remainingBalance;
  }

  /// Calculate prepayment savings
  static Map<String, dynamic> calculatePrepayment({
    required double principalAmount,
    required double annualInterestRate,
    required int tenureMonths,
    required double prepaymentAmount,
    required int monthOfPrepayment,
  }) {
    final originalEMI = calculateEMI(
      principalAmount: principalAmount,
      annualInterestRate: annualInterestRate,
      tenureMonths: tenureMonths,
    );

    final remainingBalance = getRemainingBalance(
      principalAmount: principalAmount,
      annualInterestRate: annualInterestRate,
      tenureMonths: tenureMonths,
      monthsPaid: monthOfPrepayment,
    );

    final newBalance =
        (remainingBalance - prepaymentAmount).clamp(0.0, double.infinity);
    final remainingMonths = tenureMonths - monthOfPrepayment;

    final originalTotalInterest = calculateTotalInterest(
      principalAmount: principalAmount,
      annualInterestRate: annualInterestRate,
      tenureMonths: tenureMonths,
    );

    final newEMI = calculateEMI(
      principalAmount: newBalance,
      annualInterestRate: annualInterestRate,
      tenureMonths: remainingMonths,
    );

    final newTotalInterest = (newEMI * remainingMonths);
    final interestSaved = originalTotalInterest -
        ((originalEMI * monthOfPrepayment) + newTotalInterest);

    return {
      'originalEMI': originalEMI,
      'newEMI': newEMI,
      'originalTotalInterest': originalTotalInterest,
      'newTotalInterest': newTotalInterest,
      'interestSaved': interestSaved.clamp(0.0, double.infinity),
      'remainingBalance': newBalance,
      'remainingMonths': remainingMonths,
    };
  }
}

class AmortizationEntry {
  final int monthNumber;
  final double emi;
  final double principalComponent;
  final double interestComponent;
  final double remainingBalance;

  AmortizationEntry({
    required this.monthNumber,
    required this.emi,
    required this.principalComponent,
    required this.interestComponent,
    required this.remainingBalance,
  });
}
