import 'package:app/src/features/proformas/data/datasources/proforma_local_datasource.dart';
import 'package:app/src/features/proformas/data/models/proforma_model.dart';
import 'package:app/src/features/proformas/domain/entities/proforma.dart';
import 'package:app/src/features/proformas/domain/repositories/proforma_repository.dart';

class ProformaRepositoryImpl implements ProformaRepository {
  ProformaRepositoryImpl({ProformaLocalDataSource? localDataSource})
      : _localDataSource = localDataSource ?? ProformaLocalDataSource();

  final ProformaLocalDataSource _localDataSource;

  @override
  Future<void> createProforma(Proforma proforma) async {
    final model = ProformaModel.fromEntity(proforma);
    await _localDataSource.createProforma(model);
  }

  @override
  Future<void> updateProforma(Proforma proforma) async {
    final model = ProformaModel.fromEntity(proforma);
    await _localDataSource.updateProforma(model);
  }

  @override
  Future<List<Proforma>> getProformas() async {
    final models = await _localDataSource.getProformas();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Proforma?> getProformaById(String id) async {
    final model = await _localDataSource.getProformaById(id);
    return model?.toEntity();
  }
}
