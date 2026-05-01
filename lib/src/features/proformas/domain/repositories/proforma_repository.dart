import 'package:app/src/features/proformas/domain/entities/proforma.dart';

abstract class ProformaRepository {
  Future<void> createProforma(Proforma proforma);
  Future<void> updateProforma(Proforma proforma);
  Future<List<Proforma>> getProformas();
  Future<Proforma?> getProformaById(String id);
}
