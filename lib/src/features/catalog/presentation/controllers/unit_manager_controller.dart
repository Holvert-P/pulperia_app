import 'package:app/src/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:app/src/features/catalog/domain/entities/unit_of_measure.dart';
import 'package:app/src/features/catalog/domain/usecases/catalog_usecases.dart';
import 'package:flutter/foundation.dart';

class UnitManagerController extends ChangeNotifier {
  UnitManagerController({
    GetUnitsOfMeasure? getUnits,
    SaveUnitOfMeasure? saveUnit,
  }) : _getUnits = getUnits ?? GetUnitsOfMeasure(CatalogRepositoryImpl()),
       _saveUnit = saveUnit ?? SaveUnitOfMeasure(CatalogRepositoryImpl());

  final GetUnitsOfMeasure _getUnits;
  final SaveUnitOfMeasure _saveUnit;

  bool _loading = false;
  String _query = '';
  List<UnitOfMeasure> _items = const [];

  bool get loading => _loading;
  String get query => _query;
  List<UnitOfMeasure> get items => _items;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _items = await _getUnits(includeInactive: true, query: _query);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> search(String value) async {
    _query = value;
    await load();
  }

  Future<void> save(UnitOfMeasure unit) async {
    await _saveUnit(unit);
    await load();
  }

  Future<void> toggle(UnitOfMeasure unit) {
    return save(unit.copyWith(isActive: !unit.isActive));
  }
}
