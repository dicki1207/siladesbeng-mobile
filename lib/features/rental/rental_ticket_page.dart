import 'package:flutter/material.dart';

class RentalTicketPage extends StatelessWidget {
  final String itemName;
  final String renterName;
  final String eventType;
  final bool needsLogistics;
  final int totalPrice;
  final int durationDays;

  const RentalTicketPage({
    super.key,
    required this.itemName,
    required this.renterName,
    required this.eventType,
    required this.needsLogistics,
    required this.totalPrice,
    required this.durationDays,
  });

  void _simulateWhatsApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Membuka WhatsApp: Halo Pengurus, saya ingin konfirmasi E-Tiket penyewaan gedung...',
        ),
        backgroundColor: Colors.blue[800],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF10192A) : Colors.grey[200],
      appBar: AppBar(
        title: const Text(
          'E-Tiket Reservasi',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeOutQuart,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: child,
            ),
          );
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Karcis Container
              Container(
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).cardColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Ticket Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue[900],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'BUKTI RESERVASI',
                          style: TextStyle(
                            color: Colors.white70,
                            letterSpacing: 2,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          itemName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Ticket Body
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Nama Penyewa', renterName),
                        const Divider(height: 24),
                        _buildInfoRow('Tipe Acara', eventType),
                        const Divider(height: 24),
                        _buildInfoRow('Lama Sewa', '$durationDays Hari'),
                        const Divider(height: 24),
                        _buildInfoRow(
                          'Total Biaya',
                          totalPrice == 0 ? 'GRATIS' : 'Rp $totalPrice',
                        ),

                        if (needsLogistics) ...[
                          const Divider(height: 24),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.blue.withAlpha(40) : Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.inventory_2,
                                  color: isDark ? Colors.blue[300] : Colors.blue[800],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Membutuhkan logistik tambahan (Kursi/Speaker) dari dalam gudang.',
                                    style: TextStyle(
                                      color: isDark ? Colors.blue[200] : Colors.blue[900],
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Ticket Dashed Line Separator
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            height: 20,
                            width: 10,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF10192A) : const Color(0xFFEEEEEE),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                '----------------------------------------------------',
                                maxLines: 1,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 20,
                            width: 10,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF10192A) : const Color(0xFFEEEEEE),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  bottomLeft: Radius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Ticket Footer (QR Code)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text(
                          'Tunjukkan QR Code ini kepada pengurus',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        Icon(
                          Icons.qr_code_2,
                          size: 150,
                          color: Colors.blue[900],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ID: RES-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Instruction Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).cardColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.blue[900]! : Colors.blue[100]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: isDark ? Colors.blue[300] : Colors.blue[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Instruksi Hari H',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Harap hubungi pengurus gedung untuk keperluan serah terima kunci gedung dan pengambilan fasilitas dari gudang (jika ada).',
                    style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black87),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // WhatsApp Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () => _simulateWhatsApp(context),
                icon: const Icon(
                  Icons.wechat,
                  size: 28,
                ), // using wechat as alternative if WA icon missing
                label: const Text(
                  'Halo Layanan (Hubungi Pengurus)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }
}
