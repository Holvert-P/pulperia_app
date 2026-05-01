import 'package:app/src/features/proformas/domain/entities/proforma.dart';
import 'package:app/src/features/proformas/domain/usecases/proforma_usecases.dart';
import 'package:flutter/foundation.dart';

class ProformaListController extends ChangeNotifier {
  ProformaListController({required GetProformas getProformas})
      : _getProformas = getProformas;

  final GetProformas _getProformas;

  bool _loading = false;
  String? _error;
  List<Proforma> _items = const [];

  bool get loading => _loading;
  String? get error => _error;
  List<Proforma> get items => _items;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _getProformas();
    } catch (e) {
      _error = 'No se pudieron cargar las proformas';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
