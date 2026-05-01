import 'package:app/src/features/debts/domain/entities/collection_action.dart';

class CollectionActionModel {
  const CollectionActionModel({
    required this.id,
    required this.receivableId,
    required this.type,
    required this.note,
    required this.actionAt,
    required this.createdAt,
  });

  final int? id;
  final String receivableId;
  final String type;
  final String? note;
  final DateTime actionAt;
  final DateTime createdAt;

  factory CollectionActionModel.fromMap(Map<String, Object?> map) {
    return CollectionActionModel(
      id: map['id'] as int?,
      receivableId: map['receivable_id'] as String,
      type: map['type'] as String,
      note: map['note'] as String?,
      actionAt: DateTime.parse(map['action_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'receivable_id': receivableId,
      'type': type,
      'note': note,
      'action_at': actionAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  CollectionAction toEntity() {
    return CollectionAction(
      id: id,
      receivableId: receivableId,
      type: type,
      note: note,
      actionAt: actionAt,
      createdAt: createdAt,
    );
  }
}
