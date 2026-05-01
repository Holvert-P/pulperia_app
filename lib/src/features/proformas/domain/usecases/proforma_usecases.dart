import 'package:app/src/features/proformas/domain/entities/proforma.dart';
import 'package:app/src/features/proformas/domain/repositories/proforma_repository.dart';

class GetProformas {
  const GetProformas(this._repository);

  final ProformaRepository _repository;

  Future<List<Proforma>> call() => _repository.getProformas();
}

class GetProformaById {
  const GetProformaById(this._repository);

  final ProformaRepository _repository;

  Future<Proforma?> call(String id) => _repository.getProformaById(id);
}

class CreateProforma {
  const CreateProforma(this._repository);

  final ProformaRepository _repository;

  Future<void> call(Proforma proforma) => _repository.createProforma(proforma);
}

class UpdateProforma {
  const UpdateProforma(this._repository);

  final ProformaRepository _repository;

  Future<void> call(Proforma proforma) => _repository.updateProforma(proforma);
}
