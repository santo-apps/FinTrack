import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/core/constants/app_constants.dart';
import 'package:fintrack/features/loan/data/models/loan_model.dart';
import 'package:fintrack/features/loan/presentation/providers/loan_provider.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';

class RecordPaymentDialog extends StatefulWidget {
  final Loan loan;

  const RecordPaymentDialog({super.key, required this.loan});

  @override
  State<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isEmiAmount = true;

  @override
  void initState() {
    super.initState();
    // Pre-fill with EMI amount
    _amountController.text = widget.loan.monthlyEmi.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _recordPayment() {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Amount must be greater than 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newPaidAmount = widget.loan.paidAmount + amount;

    if (newPaidAmount > widget.loan.borrowedAmount) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payment Exceeds Loan'),
          content: Text(
            'The payment amount exceeds the remaining loan balance. '
            'Remaining: ${AppUtils.formatCurrency(widget.loan.pendingAmount, currencySymbol: context.read<SettingsProvider>().currencySymbol)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    context.read<LoanProvider>().makePayment(widget.loan.id, amount);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Payment of ${AppUtils.formatCurrency(amount, currencySymbol: context.read<SettingsProvider>().currencySymbol)} recorded'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.watch<SettingsProvider>().currencySymbol;
    final remainingAmount = widget.loan.pendingAmount;

    return AlertDialog(
      title: Text(
        'Record Payment',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loan Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.loan.lender,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Remaining',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      Text(
                        AppUtils.formatCurrency(
                          remainingAmount,
                          currencySymbol: currencySymbol,
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'EMI Amount',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      Text(
                        AppUtils.formatCurrency(
                          widget.loan.monthlyEmi,
                          currencySymbol: currencySymbol,
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick select buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isEmiAmount = true;
                        _amountController.text =
                            widget.loan.monthlyEmi.toStringAsFixed(2);
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color:
                            _isEmiAmount ? AppTheme.primaryColor : Colors.grey,
                        width: _isEmiAmount ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      'EMI Amount',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            _isEmiAmount ? AppTheme.primaryColor : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isEmiAmount = false;
                        _amountController.text =
                            remainingAmount.toStringAsFixed(2);
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color:
                            !_isEmiAmount ? AppTheme.primaryColor : Colors.grey,
                        width: !_isEmiAmount ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      'Full Amount',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            !_isEmiAmount ? AppTheme.primaryColor : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Payment Amount
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Payment Amount',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.attach_money),
                prefixText: currencySymbol,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter payment amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Please enter a valid amount';
                }
                if (amount > remainingAmount) {
                  return 'Amount exceeds remaining balance';
                }
                return null;
              },
              onChanged: (_) {
                setState(() {
                  _isEmiAmount = false;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _recordPayment,
          child: const Text('Record Payment'),
        ),
      ],
    );
  }
}
