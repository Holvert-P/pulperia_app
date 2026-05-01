import 'package:app/src/features/proformas/domain/entities/proforma.dart';
import 'package:app/src/features/proformas/domain/usecases/proforma_usecases.dart';
import 'package:flutter/foundation.dart';

class ProformaDetailController extends ChangeNotifier {
  ProformaDetailController({
    required GetProformaById getProformaById,
    required String proformaId,
  }) : _getProformaById = getProformaById,
       _proformaId = proformaId;

  final GetProformaById _getProformaById;
  final String _proformaId;

  bool _loading = false;
  String? _error;
  Proforma? _proforma;

  bool get loading => _loading;
  String? get error => _error;
  Proforma? get proforma => _proforma;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _proforma = await _getProformaById(_proformaId);
      if (_proforma == null) {
        _error = 'Proforma no encontrada';
      }
    } catch (e) {
      _error = 'No se pudo cargar la proforma';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
