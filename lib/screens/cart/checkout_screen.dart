import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/cart_service.dart';
import '../profile/transaction_history_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String selectedPaymentMethod = 'UPI';

  final _upiUsernameController = TextEditingController();
  
  final List<String> upiSuffixes = ['okaxis', 'oksbi', 'okicici', 'paytm', 'ybl', 'apl'];
  late String selectedSuffix;

  bool isVerifying = false;
  bool isVerified = false;
  String? upiError;

  final orange = Colors.deepOrange;

  @override
  void initState() {
    super.initState();
    selectedSuffix = upiSuffixes[0];
  }

  @override
  void dispose() {
    _upiUsernameController.dispose();
    super.dispose();
  }

  Future<void> _verifyUPI() async {
    final username = _upiUsernameController.text.trim();
    if (username.isEmpty) {
      setState(() => upiError = 'Enter ID');
      return;
    }

    setState(() {
      isVerifying = true;
      upiError = null;
    });

    // Simulate Secure Bank Verification
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isVerifying = false;
      isVerified = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final total = cart.totalPrice + 20;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Complete Payment', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 20)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildPriceCard(total),
            const SizedBox(height: 32),
            const Text(
              'Select Payment Method',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.5),
            ),
            const SizedBox(height: 16),
            _paymentOptionTile('UPI', Icons.bolt, 'Instant transfer via UPI apps'),
            _paymentOptionTile('Credit / Debit Card', Icons.credit_card, 'Secure card payments'),
            _paymentOptionTile('Cash on Delivery', Icons.handshake_outlined, 'Pay during pickup'),
            
            const SizedBox(height: 24),
            
            if (selectedPaymentMethod == 'UPI') _buildUPIDetails(),
            if (selectedPaymentMethod == 'Credit / Debit Card') _buildCardDetails(),
            
            const SizedBox(height: 40),
            _buildPayButton(context, total),
            const SizedBox(height: 20),
            const Center(
              child: Text('🔒 Your transaction is 256-bit encrypted',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard(double total) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Payable Amount', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)),
              SizedBox(height: 4),
              Text('Rental + Service Fee', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          Text(
            '₹$total',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _paymentOptionTile(String title, IconData icon, String sub) {
    bool isSelected = selectedPaymentMethod == title;
    return GestureDetector(
      onTap: () => setState(() {
        selectedPaymentMethod = title;
        isVerified = false;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[50] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[200]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? orange : Colors.grey, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: isSelected ? Colors.black : Colors.grey[700])),
                  Text(sub, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.radio_button_checked, color: Colors.black, size: 20),
            if (!isSelected) Icon(Icons.radio_button_off, color: Colors.grey[300], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUPIDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('UPI Identity', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _upiUsernameController,
                  onChanged: (_) => setState(() => isVerified = false),
                  decoration: const InputDecoration(
                    hintText: 'Enter name/ID',
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const Text('@', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButton<String>(
                  value: selectedSuffix,
                  underline: const SizedBox(),
                  isExpanded: true,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedSuffix = newValue!;
                      isVerified = false;
                    });
                  },
                  items: upiSuffixes.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        if (upiError != null) Padding(
          padding: const EdgeInsets.only(top: 8, left: 4),
          child: Text(upiError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: isVerifying || isVerified ? null : _verifyUPI,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: isVerified ? Colors.green : Colors.black),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: isVerifying
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : Text(isVerified ? '✓ Verified by Bank' : 'Verify ID', 
                    style: TextStyle(color: isVerified ? Colors.green : Colors.black, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildCardDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(16)),
      child: const Column(
        children: [
          TextField(decoration: InputDecoration(hintText: '16-digit Card Number', border: InputBorder.none, hintStyle: TextStyle(fontSize: 14))),
          Divider(),
          Row(
            children: [
              Expanded(child: TextField(decoration: InputDecoration(hintText: 'MM/YY', border: InputBorder.none, hintStyle: TextStyle(fontSize: 14)))),
              VerticalDivider(),
              Expanded(child: TextField(decoration: InputDecoration(hintText: 'CVV', border: InputBorder.none, hintStyle: TextStyle(fontSize: 14)))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton(BuildContext context, double total) {
    bool canPay = selectedPaymentMethod != 'UPI' || isVerified;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canPay ? () => _showAppSelection(context, total) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          disabledBackgroundColor: Colors.grey[300],
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text(
          'Confirm & Pay ₹$total',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
    );
  }

  void _showAppSelection(BuildContext context, double total) {
    if (selectedPaymentMethod != 'UPI') {
      _processPayment(context, 'Payment');
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select UPI App', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _appTile('Google Pay', context),
              _appTile('PhonePe', context),
              _appTile('Paytm', context),
              _appTile('BHIM UPI', context),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _appTile(String name, BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.account_balance_wallet, color: Colors.blue),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: () {
        Navigator.pop(context);
        _processPayment(context, name);
      },
    );
  }

  void _processPayment(BuildContext context, String appName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Scaffold(
        backgroundColor: Colors.white.withOpacity(0.95),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.deepOrange),
              const SizedBox(height: 24),
              Text(
                'Redirecting to $appName...',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              const Text('Please complete the payment in the app', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pop(context); // Close redirecting
      
      context.read<CartService>().clearCart();

      _showSuccessDialog(context);
    });
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              const Text('Booking Confirmed!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                'Your payment was successful and your rental is scheduled.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()),
                      (route) => route.isFirst,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('View Booking History', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
