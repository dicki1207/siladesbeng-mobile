import 'package:flutter/material.dart';

class DeliveryTrackingPage extends StatefulWidget {
  final String orderNumber;
  final String type;
  final String deliveryAddress;

  const DeliveryTrackingPage({
    super.key,
    required this.orderNumber,
    required this.type,
    required this.deliveryAddress,
  });

  @override
  State<DeliveryTrackingPage> createState() => _DeliveryTrackingPageState();
}

class _DeliveryTrackingPageState extends State<DeliveryTrackingPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F8FF);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final labelColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Lacak Pengantaran',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            tooltip: 'Bantuan',
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ===== STATUS HEADER =====
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimasi tiba 09:23 - 09:33',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.type == 'Ambulans'
                                ? 'Ambulans sedang menuju ke lokasimu'
                                : 'Supir sedang mengantar pesananmu',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.type == 'Ambulans'
                                ? Icons.emergency
                                : Icons.local_shipping,
                            size: 40,
                            color: widget.type == 'Ambulans'
                                ? Colors.red
                                : const Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // STEPPER BAR
                    Row(
                      children: [
                        _buildStepIndicator(isCompleted: true, isActive: false),
                        _buildStepLine(isCompleted: true),
                        _buildStepIndicator(isCompleted: true, isActive: true),
                        _buildStepLine(isCompleted: false),
                        _buildStepIndicator(isCompleted: false, isActive: false),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Kami akan memberitahu kamu saat pesanan hampir tiba',
                      style: TextStyle(
                        fontSize: 12,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    const SizedBox(height: 12),
                    // DRIVER PROFILE
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FERDI KURNIAWAN (Supir)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 15),
                                  const SizedBox(width: 3),
                                  Text(
                                    '4.9',
                                    style: TextStyle(fontSize: 12, color: labelColor),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: labelColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'BM 6262 BP',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: textColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Action buttons
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.withAlpha(50)),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.call_outlined, size: 18),
                            color: textColor,
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.withAlpha(50)),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.chat_bubble_outline, size: 18),
                            color: textColor,
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // ===== DETAIL LOKASI =====
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.red[600],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Diambil dari',
                          style: TextStyle(
                            fontSize: 13,
                            color: labelColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unit Pelayanan BUMDes',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Jl. Utama Desa, Kantor BUMDes',
                            style: TextStyle(
                              fontSize: 13,
                              color: labelColor,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.more_vert,
                            color: Colors.grey[400],
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.green[600],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Diantar ke',
                          style: TextStyle(
                            fontSize: 13,
                            color: labelColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lokasi Tujuan Anda',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.deliveryAddress,
                            style: TextStyle(
                              fontSize: 13,
                              color: labelColor,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator({required bool isCompleted, required bool isActive}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isActive || isCompleted ? Colors.orange[800] : Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          isCompleted ? Icons.check : (isActive ? Icons.local_shipping : Icons.home),
          size: 14,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStepLine({required bool isCompleted}) {
    return Expanded(
      child: Container(
        height: 4,
        color: isCompleted ? Colors.orange[800] : Colors.grey[300],
      ),
    );
  }
}
