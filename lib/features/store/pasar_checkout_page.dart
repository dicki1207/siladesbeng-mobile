// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:siladesbeng_mobile/services/pasar_checkout_service.dart';

class PasarCheckoutPage extends StatefulWidget {
  final double totalAmount;
  
  const PasarCheckoutPage({super.key, required this.totalAmount});

  @override
  State<PasarCheckoutPage> createState() => _PasarCheckoutPageState();
}

class _PasarCheckoutPageState extends State<PasarCheckoutPage> {
  final PasarCheckoutService _pasarCheckoutService = PasarCheckoutService();
  String _deliveryMethod = 'Ambil Sendiri';
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  final formatCurrency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  void _submitOrder() async {
    if (_deliveryMethod == 'Diantar' && _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat pengiriman wajib diisi untuk layanan Diantar')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final result = await _pasarCheckoutService.checkout(
      _deliveryMethod,
      deliveryAddress: _deliveryMethod == 'Diantar' ? _addressController.text : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
      );
      // Back to store or home
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Metode Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Ambil Sendiri', style: TextStyle(fontSize: 14)),
                    value: 'Ambil Sendiri',
                    groupValue: _deliveryMethod,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) => setState(() => _deliveryMethod = value!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Diantar', style: TextStyle(fontSize: 14)),
                    value: 'Diantar',
                    groupValue: _deliveryMethod,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) => setState(() => _deliveryMethod = value!),
                  ),
                ),
              ],
            ),
            if (_deliveryMethod == 'Diantar') ...[
              const SizedBox(height: 16),
              const Text('Alamat Lengkap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _addressController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Masukkan alamat pengiriman',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text('Catatan (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Contoh: Titip di pos satpam',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Pembayaran', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(
                    formatCurrency.format(widget.totalAmount),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0EA5E9)),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Buat Pesanan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
