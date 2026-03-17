import 'package:flutter/material.dart';

class CartItem {
  final String toolId;
  final String name;
  final String imageUrl;
  final double pricePerDay;
  final int days;

  CartItem({
    required this.toolId,
    required this.name,
    required this.imageUrl,
    required this.pricePerDay,
    required this.days,
  });

  // Automatically calculates the total for this specific tool
  double get totalItemPrice => pricePerDay * days;
}

class CartService extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;

  // Gets the number of unique items in the cart (for the red badge)
  int get itemCount => _items.length;

  // Calculates the grand total for the checkout screen
  double get grandTotal {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.totalItemPrice;
    });
    return total;
  }

  // Adds a tool to the cart with the number of days requested
  void addItem(String toolId, String name, String imageUrl, double pricePerDay, int days) {
    if (_items.containsKey(toolId)) {
      // If it's already in the cart, just update the days
      _items.update(
        toolId,
            (existingItem) => CartItem(
          toolId: existingItem.toolId,
          name: existingItem.name,
          imageUrl: existingItem.imageUrl,
          pricePerDay: existingItem.pricePerDay,
          days: days,
        ),
      );
    } else {
      // Add brand new item
      _items.putIfAbsent(
        toolId,
            () => CartItem(
          toolId: toolId,
          name: name,
          imageUrl: imageUrl,
          pricePerDay: pricePerDay,
          days: days,
        ),
      );
    }
    // 📢 THIS IS CRITICAL: This tells the whole app to redraw the cart icons!
    notifyListeners();
  }

  void removeItem(String toolId) {
    _items.remove(toolId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}