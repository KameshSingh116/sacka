import 'package:flutter/material.dart';
import '../models/tool_model.dart';

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<Tool> _items = [];

  List<Tool> get items => List.unmodifiable(_items);

  double get totalPrice => _items.fold(0, (sum, item) => sum + item.pricePerDay);

  void addToCart(Tool tool) {
    _items.add(tool);
    notifyListeners();
  }

  void removeFromCart(Tool tool) {
    _items.remove(tool);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
