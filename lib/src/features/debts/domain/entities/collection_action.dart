class CollectionAction {
  const CollectionAction({
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
}

