import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // 🛠️ Added Storage
import 'login_screen.dart';
import 'join_node_screen.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // 🛠️ NEW: Category selection to match your Home Screen!
  String _selectedCategory = 'Drills';
  final List<String> _categories = ['Drills', 'Ladders', 'Gardening', 'Electrical'];

  bool _isUploading = false; // Prevents double-clicks

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Slightly compressed for faster uploads
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _submitTool() async {
    // 1. Check Auth & Fields
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showLoginDialog();
      return;
    }

    final toolName = _nameController.text.trim();
    final toolPrice = _priceController.text.trim();

    if (toolName.isEmpty || toolPrice.isEmpty) {
      _showError('Please enter both the Tool Name and Price!');
      return;
    }

    if (_selectedImage == null) {
      _showError('Please pick an image for your tool!');
      return;
    }

    setState(() => _isUploading = true);

    try {
      // 2. 🔒 Check Society Verification
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();

      bool isVerified = false;
      String societyCode = '';
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data() as Map<String, dynamic>;
        isVerified = data['isVerified'] ?? false;
        societyCode = data['societyCode'] ?? '';
      }

      if (!isVerified || societyCode.isEmpty) {
        _showVerificationDialog();
        setState(() => _isUploading = false);
        return;
      }

      // 3. ☁️ Upload Image to Firebase Storage
      // Create a unique file name using the current timestamp
      String fileName = 'tools/${DateTime.now().millisecondsSinceEpoch}_${currentUser.uid}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

      UploadTask uploadTask = storageRef.putFile(_selectedImage!);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL(); // Get the secure web link!

      // 4. 📝 Save Tool Data to Firestore
      await FirebaseFirestore.instance.collection('tools').add({
        'name': toolName,
        'pricePerDay': double.parse(toolPrice),
        'category': _selectedCategory,
        'imageUrl': downloadUrl, // Save the link, not the file!
        'ownerId': currentUser.uid,
        'societyCode': societyCode, // Locks the tool to their community!
        'isAvailable': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ✅ Success!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tool added successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context); // Send them back to the home screen
      }

    } catch (e) {
      _showError('Failed to upload tool: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // --- Helper Dialogs ---
  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('You must be logged in to add a new tool.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verification Required'),
        content: const Text('You must join and verify your local society before you can list tools for rent.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00)),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinNodeScreen()));
            },
            child: const Text('Join a Society', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Tool')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_selectedImage != null) ...[
            ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_selectedImage!, height: 180, width: double.infinity, fit: BoxFit.cover)),
            const SizedBox(height: 8),
            TextButton.icon(onPressed: _pickImage, icon: const Icon(Icons.refresh), label: const Text('Change Image')),
          ] else ...[
            Container(
              height: 150, width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[400]!)),
              child: Center(child: ElevatedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.image), label: const Text('Pick Image'))),
            ),
          ],
          const SizedBox(height: 24),

          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Tool Name', border: OutlineInputBorder())),
          const SizedBox(height: 16),

          TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price per day (₹)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
          const SizedBox(height: 16),

          // 🛠️ Dropdown for Categories
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
            items: _categories.map((String category) {
              return DropdownMenuItem(value: category, child: Text(category));
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) setState(() => _selectedCategory = newValue);
            },
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00)),
              onPressed: _isUploading ? null : _submitTool,
              child: _isUploading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Add Tool', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}