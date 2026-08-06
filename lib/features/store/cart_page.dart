import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:siladesbeng_mobile/services/pasar_cart_service.dart';
import 'pasar_checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final PasarCartService _pasarCartService = PasarCartService();
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCart();
  }

  Future<void> _fetchCart() async {
    setState(() => _isLoading = true);
    final items = await _pasarCartService.getCart();
    if (mounted) {
      setState(() {
        _cartItems = items;
        _isLoading = false;
      });
    }
  }

  double get _totalPrice {
    return _cartItems.fold(0, (sum, item) {
      dynamic price = item['price'] ?? 0;
      int quantity = item['quantity'] ?? 0;
      double parsedPrice = (price is String) ? (double.tryParse(price) ?? 0) : (price as num).toDouble();
      return sum + (parsedPrice * quantity);
    });
  }

  final formatCurrency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Keranjang Belanja',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cartItems.isEmpty
              ? const Center(child: Text('Keranjang Anda kosong'))
              : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: (item['image_url'] != null)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item['image_url'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.handyman, color: Colors.grey),
                                  ),
                                )
                              : const Icon(Icons.handyman, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatCurrency.format((item['price'] is String) ? double.tryParse(item['price']) ?? 0 : item['price']),
                                style: const TextStyle(color: Color(0xFF0EA5E9), fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () async {
                                final currentQty = item['quantity'];
                                if (currentQty > 1) {
                                  setState(() => item['quantity']--);
                                  bool success = await _pasarCartService.updateCart(item['id'], item['quantity']);
                                  if (!success) {
                                    setState(() => item['quantity']++); // revert
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengubah kuantitas')));
                                    }
                                  }
                                } else {
                                  bool success = await _pasarCartService.removeFromCart(item['id']);
                                  if (success && mounted) {
                                    setState(() => _cartItems.removeAt(index));
                                  }
                                }
                              },
                            ),
                            Text('${item['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () async {
                                final stock = item['stock'] ?? 0;
                                if (item['quantity'] >= stock) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok tidak mencukupi')));
                                  return;
                                }
                                setState(() => item['quantity']++);
                                bool success = await _pasarCartService.updateCart(item['id'], item['quantity']);
                                if (!success) {
                                  setState(() => item['quantity']--); // revert
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengubah kuantitas')));
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
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
                    formatCurrency.format(_totalPrice),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0EA5E9)),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _cartItems.isEmpty ? null : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PasarCheckoutPage(totalAmount: _totalPrice),
                    ),
                  ).then((_) {
                    // Refresh cart when returning from checkout
                    _fetchCart();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Checkout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
