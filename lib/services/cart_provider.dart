import 'package:flutter/material.dart';
import '../models/pedido.dart';
import '../models/produto.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  Map<String, CartItem> get items => _items;
  int get itemCount => _items.length;
  double get total => _items.values.fold(0.0, (sum, item) => sum + item.subtotal);

  void addItem(Produto p) {
    if (_items.containsKey(p.id)) {
      _items.update(p.id, (e) => CartItem(produto: e.produto, quantidade: e.quantidade + 1));
    } else {
      _items.putIfAbsent(p.id, () => CartItem(produto: p, quantidade: 1));
    }
    notifyListeners();
  }

  void updateQuantity(String id, int qty) {
    if (!_items.containsKey(id)) return;
    if (qty <= 0) _items.remove(id);
    else _items.update(id, (e) => CartItem(produto: e.produto, quantidade: qty));
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}