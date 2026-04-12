import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/api_client.dart';
import 'widgets/driver_button.dart';

class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  final _vpaController = TextEditingController();
  final _accountController = TextEditingController();
  final _ifscController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_vpaController.text.trim().isEmpty && _accountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter UPI ID or Account Details')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiClient().createFundAccount({
        'vpa': _vpaController.text.trim(),
        'accountNumber': _accountController.text.trim(),
        'ifsc': _ifscController.text.trim(),
        // Backend maps to razorpayContactId internally
      });

      if (res.data['status'] == 'OK') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payout details added successfully!')),
        );
        Navigator.pop(context);
      } else {
        throw Exception(res.data['message'] ?? 'Failed to save');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text('Add Payout Details'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Enter your UPI ID or Bank Details to receive payouts from your wallet.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _vpaController,
              decoration: const InputDecoration(
                labelText: 'UPI ID (VPA)',
                hintText: 'e.g. 9876543210@ybl',
                filled: true,
                fillColor: Colors.black45,
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('OR', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
            ),
            TextField(
              controller: _accountController,
              decoration: const InputDecoration(
                labelText: 'Account Number',
                filled: true,
                fillColor: Colors.black45,
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ifscController,
              decoration: const InputDecoration(
                labelText: 'IFSC Code',
                filled: true,
                fillColor: Colors.black45,
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const Spacer(),
            DriverButton(
              onPressed: _isLoading ? () {} : _submit,
              backgroundColor: AppTheme.primaryGold,
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text('SAVE DETAILS', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}
