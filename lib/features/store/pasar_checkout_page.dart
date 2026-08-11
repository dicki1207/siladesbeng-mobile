// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:siladesbeng_mobile/services/pasar_checkout_service.dart';
import 'package:siladesbeng_mobile/features/store/pasar_payment_page.dart';

class PasarCheckoutPage extends StatefulWidget {
  final double totalAmount;
  
  const PasarCheckoutPage({super.key, required this.totalAmount});

  @override
  State<PasarCheckoutPage> createState() => _PasarCheckoutPageState();
}

class _PasarCheckoutPageState extends State<PasarCheckoutPage> {
  final PasarCheckoutService _pasarCheckoutService = PasarCheckoutService();
  String _deliveryMethod = 'Ambil Sendiri';
  String _paymentMethod = 'COD';
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  final formatCurrency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  double get _ongkir => _deliveryMethod == 'Diantar' ? 5000 : 0;
  double get _grandTotal => widget.totalAmount + _ongkir;

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
      paymentMethod: _paymentMethod,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      final order = result['order'];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PasarPaymentPage(
            orderId: order['id'],
            orderNumber: order['order_number'] ?? '',
            grandTotal: order['grand_total'] != null 
                ? double.parse(order['grand_total'].toString()) 
                : widget.totalAmount,
            paymentMethod: _paymentMethod,
            paymentVaNumber: order['payment_va_number'],
            paymentQrUrl: order['payment_qr_url'],
            paymentExpiryTime: order['payment_expiry_time'],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Terjadi kesalahan'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildStep(int step, String title, bool isActive, bool isFinished) {
    Color color = isActive || isFinished ? const Color(0xFF0EA5E9) : Colors.grey.shade300;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: isFinished
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text(
                  step.toString(),
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isActive || isFinished ? const Color(0xFF0EA5E9) : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStep(1, 'Keranjang', false, true),
          Expanded(child: Divider(color: const Color(0xFF0EA5E9), thickness: 2, indent: 8, endIndent: 8)),
          _buildStep(2, 'Checkout', true, false),
          Expanded(child: Divider(color: Colors.grey.shade300, thickness: 2, indent: 8, endIndent: 8)),
          _buildStep(3, 'Pembayaran', false, false),
        ],
      ),
    );
  }

  Widget _buildDeliveryOption({
    required String title,
    required String value,
    required IconData icon,
    required String badgeText,
    required Color badgeColor,
  }) {
    final isSelected = _deliveryMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _deliveryMethod = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0EA5E9).withOpacity(0.05) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF0EA5E9) : Colors.grey.shade300, 
            width: isSelected ? 2 : 1
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF0EA5E9) : Colors.grey.shade600, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(color: badgeColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF0EA5E9), size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0EA5E9).withOpacity(0.05) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF0EA5E9) : Colors.grey.shade300, 
            width: isSelected ? 2 : 1
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF0EA5E9) : Colors.grey.shade600, size: 36),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF0EA5E9) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          _buildStepper(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Metode Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  _buildDeliveryOption(
                    title: 'Ambil Sendiri',
                    value: 'Ambil Sendiri',
                    icon: Icons.store,
                    badgeText: 'Gratis',
                    badgeColor: Colors.green,
                  ),
                  _buildDeliveryOption(
                    title: 'Diantar Kurir Lokal',
                    value: 'Diantar',
                    icon: Icons.delivery_dining,
                    badgeText: 'Same-day',
                    badgeColor: const Color(0xFF0EA5E9),
                  ),
                  
                  if (_deliveryMethod == 'Diantar') ...[
                    const SizedBox(height: 20),
                    const Text('Alamat Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Masukkan alamat lengkap pengiriman...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 2),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _buildPaymentOption(
                        title: 'Tunai / COD',
                        value: 'COD',
                        icon: Icons.payments,
                      ),
                      _buildPaymentOption(
                        title: 'Transfer Bank',
                        value: 'transfer_manual',
                        icon: Icons.account_balance,
                      ),
                      _buildPaymentOption(
                        title: 'QRIS',
                        value: 'qris',
                        icon: Icons.qr_code_2,
                      ),
                      _buildPaymentOption(
                        title: 'Virtual Account',
                        value: 'virtual_account',
                        icon: Icons.credit_card,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Text('Catatan (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Titip di pos satpam, dll.',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32), // Extra padding at the bottom
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05), 
              blurRadius: 15, 
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal Barang', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  Text(formatCurrency.format(widget.totalAmount), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ongkos Kirim', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  Text(formatCurrency.format(_ongkir), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    formatCurrency.format(_grandTotal),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF0EA5E9)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Buat Pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
