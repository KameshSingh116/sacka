import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RentalPaymentScreen extends StatefulWidget {
  final String rentalId;
  final Map<String, dynamic> rentalData;

  const RentalPaymentScreen({super.key, required this.rentalId, required this.rentalData});

  @override
  State<RentalPaymentScreen> createState() => _RentalPaymentScreenState();
}

class _RentalPaymentScreenState extends State<RentalPaymentScreen> {
  bool _isProcessing = false;

  // 🛡️ THE SECURE TRANSACTION LOGIC
  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    final String toolId = widget.rentalData['toolId'];
    final DocumentReference toolRef = FirebaseFirestore.instance.collection('tools').doc(toolId);
    final DocumentReference rentalRef = FirebaseFirestore.instance.collection('rentals').doc(widget.rentalId);

    try {
      // 🔒 The Transaction: All or Nothing
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 1. Check tool status inside the lock
        DocumentSnapshot toolSnap = await transaction.get(toolRef);

        if (!toolSnap.exists || toolSnap.get('isAvailable') == false) {
          throw Exception("Too late! Someone else just secured this tool.");
        }

        // 2. If available, lock the tool and update rental

        transaction.update(rentalRef, {
          'status': 'Active',
          'paidAt': FieldValue.serverTimestamp(),
        });
      });

      // ✅ Success!
      if (!mounted) return;
      _showFinishDialog("Success!", "You secured the tool. Go pick it up!");

    } catch (e) {
      // ❌ Failed (Someone else paid first)
      if (!mounted) return;
      _showFinishDialog("Payment Failed", e.toString().replaceAll("Exception:", ""));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showFinishDialog(String title, String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify & Pay")),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text("Lender's Live Condition Photo:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  // 📸 Showing the photo the owner JUST took
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      widget.rentalData['liveImageUrl'],
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Card(
                    color: Colors.amberAccent,
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text("⚠️ RACE TO CHECKOUT: Others have also received this photo. First person to pay wins!"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: _isProcessing ? null : _processPayment,
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("PAY NOW", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }
}