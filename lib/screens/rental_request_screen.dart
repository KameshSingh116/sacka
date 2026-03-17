import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class RentalRequestScreen extends StatefulWidget {
  final String toolId;
  final Map<String, dynamic> toolData;

  const RentalRequestScreen({super.key, required this.toolId, required this.toolData});

  @override
  State<RentalRequestScreen> createState() => _RentalRequestScreenState();
}

class _RentalRequestScreenState extends State<RentalRequestScreen> {
  DateTime _startDate = DateTime.now();
  int _rentalDays = 1;
  bool _isSubmitting = false;

  // 📅 NEW: Variables for the Calendar Bouncer
  List<Map<String, DateTime>> _blockedPeriods = [];
  bool _isLoadingDates = true;

  @override
  void initState() {
    super.initState();
    _fetchBlockedDates(); // Fetch the paid dates when the screen opens!
  }

  // 🛑 FETCH ONLY FULLY PAID (ACTIVE) RENTALS
  Future<void> _fetchBlockedDates() async {
    try {
      QuerySnapshot rentals = await FirebaseFirestore.instance
          .collection('rentals')
          .where('toolId', isEqualTo: widget.toolId)
      // 🚀 RACE TO CHECKOUT: Only block the calendar if someone actually PAID!
          .where('status', isEqualTo: 'Active')
          .get();

      List<Map<String, DateTime>> periods = [];
      for (var doc in rentals.docs) {
        var data = doc.data() as Map<String, dynamic>;
        DateTime start = (data['startDate'] as Timestamp).toDate();
        DateTime end = (data['endDate'] as Timestamp).toDate();

        periods.add({
          'start': DateTime(start.year, start.month, start.day),
          'end': DateTime(end.year, end.month, end.day),
        });
      }

      setState(() {
        _blockedPeriods = periods;
        _isLoadingDates = false;

        // If today is already paid for, push the start date forward to the next free day!
        while (!_isDaySelectable(_startDate)) {
          _startDate = _startDate.add(const Duration(days: 1));
        }
      });
    } catch (e) {
      print("Error fetching dates: $e");
      setState(() => _isLoadingDates = false);
    }
  }

  // 🛑 THE CALENDAR BOUNCER: Checks if a specific day is allowed
  bool _isDaySelectable(DateTime day) {
    DateTime checkDate = DateTime(day.year, day.month, day.day);

    for (var period in _blockedPeriods) {
      DateTime start = period['start']!;
      DateTime end = period['end']!;

      if (checkDate.isAtSameMomentAs(start) ||
          checkDate.isAtSameMomentAs(end) ||
          (checkDate.isAfter(start) && checkDate.isBefore(end))) {
        return false;
      }
    }
    return true;
  }

  // ⏳ SMART DURATION CHECKER: Prevents picking a duration that bleeds into a blocked date
  void _incrementDays() {
    DateTime nextDayNeeded = _startDate.add(Duration(days: _rentalDays));

    if (!_isDaySelectable(nextDayNeeded)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("The tool is already booked by someone else on that day!"), backgroundColor: Colors.orange)
      );
      return;
    }

    setState(() => _rentalDays++);
  }

  // Function to pick a start date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      selectableDayPredicate: _isDaySelectable, // 🚀 Greys out the blocked days!
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFFF8C00)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        _rentalDays = 1; // Reset duration when picking a new start date
      });
    }
  }

  // Send the request to Firestore
  Future<void> _sendRentalRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    double pricePerDay = (widget.toolData['pricePerDay'] ?? 0.0).toDouble();
    double totalAmount = pricePerDay * _rentalDays;

    try {
      await FirebaseFirestore.instance.collection('rentals').add({
        'toolId': widget.toolId,
        'toolName': widget.toolData['name'],
        'borrowerId': user.uid,
        'lenderId': widget.toolData['ownerId'],
        'startDate': Timestamp.fromDate(_startDate),
        // 🛠️ Fixed to calculate exact end date accurately
        'endDate': Timestamp.fromDate(_startDate.add(Duration(days: _rentalDays - 1))),
        'days': _rentalDays,
        'totalAmount': totalAmount,
        'status': 'pending_verification',
        'liveImageUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request sent to owner! Waiting for their live photo."), backgroundColor: Colors.green),
      );

      // Pop back to the main feed
      Navigator.popUntil(context, (route) => route.isFirst);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double pricePerDay = (widget.toolData['pricePerDay'] ?? 0.0).toDouble();
    double totalAmount = pricePerDay * _rentalDays;

    // Show a loading spinner while fetching the calendar dates
    if (_isLoadingDates) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFFF8C00))));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Request to Rent"), elevation: 0),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C00),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSubmitting ? null : _sendRentalRequest,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Request Live Photo", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tool Summary
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(widget.toolData['imageUrl'] ?? '', height: 80, width: 80, fit: BoxFit.cover),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.toolData['name'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("₹${pricePerDay.toStringAsFixed(0)} / day", style: const TextStyle(color: Color(0xFFFF8C00), fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
            const Divider(height: 40),

            // Date Selection
            const Text("When do you need it?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFFFF8C00)),
                        const SizedBox(width: 12),
                        Text(DateFormat('MMM dd, yyyy').format(_startDate), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Icon(Icons.edit, color: Colors.grey, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Duration Selection
            const Text("For how many days?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _rentalDays > 1 ? () => setState(() => _rentalDays--) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: _rentalDays > 1 ? const Color(0xFFFF8C00) : Colors.grey,
                  ),
                  Text('$_rentalDays Days', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: _incrementDays, // 🚀 Uses the Smart Bouncer now
                    icon: const Icon(Icons.add_circle_outline),
                    color: const Color(0xFFFF8C00),
                  ),
                ],
              ),
            ),
            const Divider(height: 40),

            // Payment Summary
            const Text("Payment Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("₹${pricePerDay.toStringAsFixed(0)} x $_rentalDays days", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                Text("₹${totalAmount.toStringAsFixed(0)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),

            // 🚀 NEW: The "Race to Checkout" Warning Box!
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!)
              ),
              child: const Row(
                children: [
                  Icon(Icons.timer, color: Colors.red),
                  SizedBox(width: 12),
                  Expanded(
                      child: Text(
                          "Requesting does not reserve this tool! Whoever pays first gets it. Pay fast once the owner sends the live photo!",
                          style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)
                      )
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}