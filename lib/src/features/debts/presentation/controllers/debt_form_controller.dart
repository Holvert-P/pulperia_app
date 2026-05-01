import 'package:flutter/foundation.dart';
import 'package:app/src/features/debts/domain/usecases/receivable_usecases.dart';

class DebtFormController extends ChangeNotifier {
  DebtFormController({
    required CreateReceivableFromCreditSale createReceivableFromCreditSale,
  }) : _createReceivableFromCreditSale = createReceivableFromCreditSale;

  final CreateReceivableFromCreditSale _createReceivableFromCreditSale;

  bool _saving = false;
  String? _error;

  String _customerName = '';
  double _principalAmount = 0;
  double _monthlyRate = 0.10;
  int _generationCycleDays = 30;
  bool _appliesOnOverdueOnly = false;
  bool _compoundInterest = false;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));

  bool get saving => _saving;
  String? get error => _error;
  String get customerName => _customerName;
  double get principalAmount => _principalAmount;
  double get monthlyRate => _monthlyRate;
  int get generationCycleDays => _generationCycleDays;
  bool get appliesOnOverdueOnly => _appliesOnOverdueOnly;
  bool get compoundInterest => _compoundInterest;
  DateTime get dueDate => _dueDate;

  void setCustomerName(String value) {
    _customerName = value;
    notifyListeners();
  }

  void setTotalAmount(double value) {
    _principalAmount = value;
    notifyListeners();
  }

  void setMonthlyRate(double value) {
    _monthlyRate = value;
    notifyListeners();
  }

  void setGenerationCycleDays(int value) {
    _generationCycleDays = value;
    notifyListeners();
  }

  void setAppliesOnOverdueOnly(bool value) {
    _appliesOnOverdueOnly = value;
    notifyListeners();
  }

  void setCompoundInterest(bool value) {
    _compoundInterest = value;
    notifyListeners();
  }

  void setDueDate(DateTime value) {
    _dueDate = value;
    notifyListeners();
  }

  String? validate() {
    if (_customerName.trim().isEmpty) return 'Ingresa el nombre del cliente';
    if (_principalAmount <= 0) return 'El monto debe ser mayor a 0';
    if (_monthlyRate < 0) return 'La tasa no puede ser negativa';
    if (_generationCycleDays <= 0) {
      return 'El ciclo de generación debe ser mayor a 0';
    }
    return null;
  }

  Future<bool> save() async {
    final message = validate();
    if (message != null) {
      _error = message;
      notifyListeners();
      return false;
    }

    _saving = true;
    _error = null;
    notifyListeners();

    try {
      await _createReceivableFromCreditSale(
        customerName: _customerName.trim(),
        principalAmount: _principalAmount,
        dueDate: _dueDate,
        monthlyRate: _monthlyRate,
        generationCycleDays: _generationCycleDays,
        appliesOnOverdueOnly: _appliesOnOverdueOnly,
        compoundInterest: _compoundInterest,
      );
      return true;
    } catch (e) {
      _error = 'No se pudo guardar la cuenta por cobrar';
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}
