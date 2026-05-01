import 'package:app/src/features/products/domain/entities/product.dart';
import 'package:app/src/features/proformas/domain/entities/proforma.dart';
import 'package:app/src/features/proformas/domain/entities/proforma_item.dart';
import 'package:app/src/features/proformas/domain/usecases/proforma_usecases.dart';
import 'package:flutter/foundation.dart';

class ProformaFormController extends ChangeNotifier {
  ProformaFormController({
    required CreateProforma createProforma,
    required UpdateProforma updateProforma,
    required GetProformaById getProformaById,
    String? proformaId,
  }) : _createProforma = createProforma,
       _updateProforma = updateProforma,
       _getProformaById = getProformaById,
       _proformaId = proformaId;

  final CreateProforma _createProforma;
  final UpdateProforma _updateProforma;
  final GetProformaById _getProformaById;
  final String? _proformaId;

  bool _loading = false;
  bool _saving = false;
  String? _error;
  String? _lastSavedId;
  String _customerName = '';
  DateTime? _createdAt;
  List<ProformaItem> _items = const [];
  double _discount = 0.0;

  bool get loading => _loading;
  bool get saving => _saving;
  String? get error => _error;
  bool get isEdit => _proformaId != null;
  String? get lastSavedId => _lastSavedId;
  String get customerName => _customerName;
  List<ProformaItem> get items => _items;
  double get discount => _discount;
  double get subtotal => _calculateSubtotalTotal(_items);
  double get total => _calculateTotal(subtotal, _discount);

  double _calculateSubtotal(int quantity, double price) => quantity * price;

  double _calculateSubtotalTotal(List<ProformaItem> items) {
    return items.fold<double>(0, (sum, i) => sum + i.subtotal);
  }

  double _calculateTotal(double subtotal, double discount) {
    final next = subtotal - discount;
    return next < 0 ? 0.0 : next;
  }

  void _clampDiscount() {
    final max = subtotal;
    if (_discount < 0) {
      _discount = 0.0;
    } else if (_discount > max) {
      _discount = max;
    }
  }

  void setCustomerName(String value) {
    _customerName = value;
    notifyListeners();
  }

  void setDiscount(double value) {
    _discount = value < 0 ? 0.0 : value;
    _clampDiscount();
    notifyListeners();
  }

  Future<void> loadIfEditing() async {
    final id = _proformaId;
    if (id == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final proforma = await _getProformaById(id);
      if (proforma == null) {
        _error = 'Proforma no encontrada';
        return;
      }
      _customerName = proforma.customerName;
      _createdAt = proforma.createdAt;
      _items = List<ProformaItem>.from(proforma.items);
      _discount = proforma.discount;
      _clampDiscount();
    } catch (e) {
      _error = 'No se pudo cargar la proforma';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void addProduct(Product product) {
    addProductWithQuantity(product, 1);
  }

  void addProductWithQuantity(Product product, int quantity) {
    final id = product.id;
    final qty = quantity < 1 ? 1 : quantity;

    final index = _items.indexWhere((i) => i.productId == id);
    if (index != -1) {
      final current = _items[index];
      final nextQty = current.quantity + qty;
      final nextSubtotal = _calculateSubtotal(nextQty, current.price);
      _items = List<ProformaItem>.from(_items)
        ..[index] = current.copyWith(quantity: nextQty, subtotal: nextSubtotal);
      _clampDiscount();
      notifyListeners();
      return;
    }

    final price = product.salePrice;
    final subtotal = _calculateSubtotal(qty, price);
    _items = [
      ..._items,
      ProformaItem(
        productId: id,
        name: product.name,
        quantity: qty,
        price: price,
        subtotal: subtotal,
      ),
    ];
    _clampDiscount();
    notifyListeners();
  }

  void removeItemAt(int index) {
    if (index < 0 || index >= _items.length) return;
    _items = List<ProformaItem>.from(_items)..removeAt(index);
    _clampDiscount();
    notifyListeners();
  }

  void setQuantity(int index, int quantity) {
    if (index < 0 || index >= _items.length) return;
    final clamped = quantity < 1 ? 1 : quantity;
    final current = _items[index];
    final subtotal = _calculateSubtotal(clamped, current.price);
    _items = List<ProformaItem>.from(_items)
      ..[index] = current.copyWith(quantity: clamped, subtotal: subtotal);
    _clampDiscount();
    notifyListeners();
  }

  void setPrice(int index, double price) {
    if (index < 0 || index >= _items.length) return;
    final current = _items[index];
    final nextPrice = price < 0 ? 0.0 : price;
    final subtotal = _calculateSubtotal(current.quantity, nextPrice);
    _items = List<ProformaItem>.from(_items)
      ..[index] = current.copyWith(price: nextPrice, subtotal: subtotal);
    _clampDiscount();
    notifyListeners();
  }

  String? validate() {
    if (_customerName.trim().isEmpty) return 'Ingresa el nombre del cliente';
    if (_items.isEmpty) return 'Agrega al menos un producto';
    if (_discount < 0) return 'El descuento no puede ser negativo';
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
      final now = DateTime.now();
      final id = _proformaId ?? now.microsecondsSinceEpoch.toString();
      final createdAt = _createdAt ?? now;
      _lastSavedId = id;
      final proforma = Proforma(
        id: id,
        customerName: _customerName.trim(),
        total: total,
        discount: discount,
        createdAt: createdAt,
        items: _items,
      );

      if (_proformaId == null) {
        await _createProforma(proforma);
      } else {
        await _updateProforma(proforma);
      }
      return true;
    } catch (e) {
      _error = 'No se pudo guardar la proforma';
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}
