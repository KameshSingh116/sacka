import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/cart_service.dart'; // Adjust path if needed based on your folder structure
import 'checkout_screen.dart'; // We will build this in the very next step!

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      // 🎧 The Consumer listens to the CartService in real-time
      body: Consumer<CartService>(
        builder: (context, cart, child) {
          // 🛑 EMPTY STATE
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey[400]),
                  const SizedBox(height: 24),
                  const Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Browse your community to find tools to rent.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C00),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context), // Go back to feed
                    child: const Text('Start Browsing', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          // ✅ CART HAS ITEMS
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, i) {
                    // Extract the item from the Map
                    String toolId = cart.items.keys.toList()[i];
                    CartItem item = cart.items.values.toList()[i];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // 🖼️ Tool Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.imageUrl,
                                height: 80,
                                width: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 80, width: 80, color: Colors.grey[200],
                                  child: const Icon(Icons.handyman, color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // 📝 Tool Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${item.pricePerDay.toStringAsFixed(0)}/day x ${item.days} Days',
                                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '₹${item.totalItemPrice.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF8C00)),
                                  ),
                                ],
                              ),
                            ),

                            // 🗑️ Delete Button
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                cart.removeItem(toolId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Item removed from cart'), duration: Duration(seconds: 1)),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 💰 BOTTOM CHECKOUT BAR
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Grand Total', style: TextStyle(fontSize: 18, color: Colors.grey)),
                          Text(
                            '₹${cart.grandTotal.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF8C00),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            // TODO: Navigate to CheckoutScreen!
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));

                            // Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
                          },
                          child: const Text('Proceed to Checkout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}