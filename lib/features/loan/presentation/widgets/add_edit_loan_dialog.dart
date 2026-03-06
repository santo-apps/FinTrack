import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fintrack/core/theme/app_theme.dart';
import 'package:fintrack/features/loan/data/models/loan_model.dart';
import 'package:fintrack/features/loan/presentation/providers/loan_provider.dart';
import 'package:fintrack/features/settings/presentation/providers/settings_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class AddEditLoanDialog extends StatefulWidget {
  final Loan? loan;

  const AddEditLoanDialog({super.key, this.loan});

  @override
  State<AddEditLoanDialog> createState() => _AddEditLoanDialogState();
}

class _AddEditLoanDialogState extends State<AddEditLoanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _lenderController = TextEditingController();
  final _borrowedAmountController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _tenureController = TextEditingController();
  final _emiController = TextEditingController();
  final _emiDateController = TextEditingController();
  final _pendingAmountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    if (widget.loan != null) {
      _lenderController.text = widget.loan!.lender;
      _borrowedAmountController.text = widget.loan!.borrowedAmount.toString();
      _interestRateController.text = widget.loan!.interestRate.toString();
      _tenureController.text = widget.loan!.tenureMonths.toString();
      _emiController.text = widget.loan!.monthlyEmi.toString();
      _emiDateController.text = widget.loan!.emiDate.toString();
      _pendingAmountController.text = widget.loan!.pendingAmount.toString();
      _notesController.text = widget.loan!.notes ?? '';
      _startDate = widget.loan!.startDate;
      _endDate = widget.loan!.endDate;
    }
  }

  @override
  void dispose() {
    _lenderController.dispose();
    _borrowedAmountController.dispose();
    _interestRateController.dispose();
    _tenureController.dispose();
    _emiController.dispose();
    _emiDateController.dispose();
    _pendingAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateEndDate() {
    if (_tenureController.text.isEmpty) {
      return;
    }

    try {
      final tenure = int.parse(_tenureController.text);
      if (tenure <= 0) {
        setState(() {
          _endDate = null;
        });
        return;
      }

      // Calculate end date
      setState(() {
        _endDate = DateTime(
          _startDate.year,
          _startDate.month + tenure,
          _startDate.day,
        );
      });
    } catch (e) {
      setState(() {
        _endDate = null;
      });
    }
  }

  Future<void> _selectStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() {
        _startDate = selected;
        _calculateEndDate(); // Recalculate end date
      });
    }
  }

  void _saveLoan() {
    if (!_formKey.currentState!.validate()) return;

    final currency = context.read<SettingsProvider>().currencySymbol;
    final borrowedAmount = double.parse(_borrowedAmountController.text);
    final pendingAmount = _pendingAmountController.text.isEmpty
        ? borrowedAmount
        : double.parse(_pendingAmountController.text);
    final paidAmount = borrowedAmount - pendingAmount;

    final loan = Loan(
      id: widget.loan?.id ?? const Uuid().v4(),
      lender: _lenderController.text.trim(),
      borrowedAmount: borrowedAmount,
      interestRate: double.parse(_interestRateController.text),
      tenureMonths: int.parse(_tenureController.text),
      monthlyEmi: double.parse(_emiController.text),
      startDate: _startDate,
      endDate: _endDate!,
      emiDate: int.parse(_emiDateController.text),
      paidAmount: paidAmount,
      createdAt: widget.loan?.createdAt ?? DateTime.now(),
      currency: currency,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    final provider = context.read<LoanProvider>();

    if (widget.loan == null) {
      provider.addLoan(loan);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loan added successfully')),
      );
    } else {
      provider.updateLoan(loan);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loan updated successfully')),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = context.watch<SettingsProvider>().currencySymbol;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.loan == null ? 'Add Loan' : 'Edit Loan',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Lender Name
                TextFormField(
                  controller: _lenderController,
                  decoration: const InputDecoration(
                    labelText: 'Lender Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter lender name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Borrowed Amount
                TextFormField(
                  controller: _borrowedAmountController,
                  decoration: InputDecoration(
                    labelText: 'Borrowed Amount',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.attach_money),
                    prefixText: currencySymbol,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter borrowed amount';
                    }
                    if (double.tryParse(value) == null ||
                        double.parse(value) <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Interest Rate and Tenure
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _interestRateController,
                        decoration: const InputDecoration(
                          labelText: 'Interest Rate (%)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.percent),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value) == null ||
                              double.parse(value) < 0) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _tenureController,
                        decoration: const InputDecoration(
                          labelText: 'Tenure (Months)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_month),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (int.tryParse(value) == null ||
                              int.parse(value) <= 0) {
                            return 'Invalid';
                          }
                          return null;
                        },
                        onChanged: (_) => _calculateEndDate(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // EMI Date
                TextFormField(
                  controller: _emiDateController,
                  decoration: const InputDecoration(
                    labelText: 'EMI Due Date (Day of Month)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.date_range),
                    hintText: 'e.g., 5 for 5th of every month',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter EMI date';
                    }
                    final day = int.tryParse(value);
                    if (day == null || day < 1 || day > 31) {
                      return 'Enter a day between 1 and 31';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Start Date
                InkWell(
                  onTap: _selectStartDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Date',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.event),
                    ),
                    child: Text(
                      DateFormat('MMM dd, yyyy').format(_startDate),
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Monthly EMI Manual Input
                TextFormField(
                  controller: _emiController,
                  decoration: InputDecoration(
                    labelText: 'Monthly EMI',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.payments),
                    prefixText: currencySymbol,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter monthly EMI';
                    }
                    if (double.tryParse(value) == null ||
                        double.parse(value) <= 0) {
                      return 'Please enter a valid EMI amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Pending Amount Manual Input
                TextFormField(
                  controller: _pendingAmountController,
                  decoration: InputDecoration(
                    labelText: 'Pending Amount',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.account_balance_wallet),
                    prefixText: currencySymbol,
                    hintText: 'Leave empty if new loan',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final pending = double.tryParse(value);
                      if (pending == null || pending < 0) {
                        return 'Please enter a valid amount';
                      }
                      final borrowed =
                          double.tryParse(_borrowedAmountController.text);
                      if (borrowed != null && pending > borrowed) {
                        return 'Cannot exceed borrowed amount';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Total Repayment Display
                Builder(
                  builder: (context) {
                    double? totalRepayment;
                    double? totalInterest;

                    final emi = double.tryParse(_emiController.text);
                    final tenure = int.tryParse(_tenureController.text);
                    final borrowed =
                        double.tryParse(_borrowedAmountController.text);

                    if (emi != null &&
                        tenure != null &&
                        borrowed != null &&
                        emi > 0 &&
                        tenure > 0 &&
                        borrowed > 0) {
                      totalRepayment = emi * tenure;
                      totalInterest = totalRepayment - borrowed;
                    }

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Repayment',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textColor,
                                ),
                              ),
                              Text(
                                totalRepayment != null
                                    ? '$currencySymbol${totalRepayment.toStringAsFixed(2)}'
                                    : '---',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          if (totalInterest != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Interest',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                                Text(
                                  '$currencySymbol${totalInterest.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_endDate != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'End Date',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM dd, yyyy').format(_endDate!),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveLoan,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.loan == null ? 'Add Loan' : 'Update Loan',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
