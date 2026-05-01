import 'package:flutter/foundation.dart';
import 'package:app/src/features/debts/domain/entities/collection_action.dart';
import 'package:app/src/features/debts/domain/entities/receivable_detail.dart';
import 'package:app/src/features/debts/domain/entities/receivable_transaction.dart';
import 'package:app/src/features/debts/domain/usecases/receivable_usecases.dart';

class DebtDetailController extends ChangeNotifier {
  DebtDetailController({
    required GetReceivableDetail getReceivableDetail,
    required GetReceivableLedger getReceivableLedger,
    required GetCollectionActions getCollectionActions,
    required GenerateReceivableInterest generateReceivableInterest,
    required ReverseReceivablePayment reverseReceivablePayment,
    required RegisterCollectionAction registerCollectionAction,
    required String debtId,
  }) : _getReceivableDetail = getReceivableDetail,
       _getReceivableLedger = getReceivableLedger,
       _getCollectionActions = getCollectionActions,
       _generateReceivableInterest = generateReceivableInterest,
       _reverseReceivablePayment = reverseReceivablePayment,
       _registerCollectionAction = registerCollectionAction,
       _receivableId = debtId;

  final GetReceivableDetail _getReceivableDetail;
  final GetReceivableLedger _getReceivableLedger;
  final GetCollectionActions _getCollectionActions;
  final GenerateReceivableInterest _generateReceivableInterest;
  final ReverseReceivablePayment _reverseReceivablePayment;
  final RegisterCollectionAction _registerCollectionAction;
  final String _receivableId;

  bool _loading = false;
  bool _working = false;
  String? _error;
  ReceivableDetail? _detail;
  List<ReceivableTransaction> _ledger = const [];
  List<CollectionAction> _collectionActions = const [];

  bool get loading => _loading;
  bool get working => _working;
  String? get error => _error;
  ReceivableDetail? get detail => _detail;
  List<ReceivableTransaction> get ledger => _ledger;
  List<CollectionAction> get collectionActions => _collectionActions;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final detail = await _getReceivableDetail(_receivableId);
      if (detail == null) {
        _error = 'Cuenta por cobrar no encontrada';
        return;
      }
      final results = await Future.wait([
        _getReceivableLedger(_receivableId),
        _getCollectionActions(_receivableId),
      ]);
      _detail = detail;
      _ledger = results.first as List<ReceivableTransaction>;
      _collectionActions = results.last as List<CollectionAction>;
    } catch (e) {
      _error = 'No se pudo cargar la cuenta por cobrar';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<int> generateInterest() async {
    if (_working) return 0;
    _working = true;
    _error = null;
    notifyListeners();
    try {
      final count = await _generateReceivableInterest(receivableId: _receivableId);
      await load();
      return count;
    } catch (e) {
      _error = 'No se pudo generar intereses';
      return 0;
    } finally {
      _working = false;
      notifyListeners();
    }
  }

  Future<bool> reverseReceipt({
    required String receiptId,
    required String reason,
    required DateTime reversedAt,
  }) async {
    if (_working) return false;
    _working = true;
    _error = null;
    notifyListeners();
    try {
      await _reverseReceivablePayment(
        receiptId: receiptId,
        reason: reason,
        reversedAt: reversedAt,
      );
      await load();
      return true;
    } catch (e) {
      _error = 'No se pudo revertir el pago';
      return false;
    } finally {
      _working = false;
      notifyListeners();
    }
  }

  Future<bool> addCollectionAction({
    required String type,
    required String note,
    required DateTime actionAt,
  }) async {
    if (_working) return false;
    if (type.trim().isEmpty) {
      _error = 'Selecciona un tipo de gestión';
      notifyListeners();
      return false;
    }
    _working = true;
    _error = null;
    notifyListeners();
    try {
      await _registerCollectionAction(
        receivableId: _receivableId,
        type: type,
        note: note,
        actionAt: actionAt,
      );
      await load();
      return true;
    } catch (e) {
      _error = 'No se pudo registrar la gestión';
      return false;
    } finally {
      _working = false;
      notifyListeners();
    }
  }
}
