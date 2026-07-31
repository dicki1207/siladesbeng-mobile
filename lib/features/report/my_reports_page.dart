import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/features/report/report_receipt_page.dart';

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({super.key});

  @override
  State<MyReportsPage> createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  List<dynamic> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyReports();
  }

  Future<void> _fetchMyReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('auth_token');

      if (token != null) {
        final res = await http.get(
          Uri.parse('http://10.193.206.148:8000/api/my-reports'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          if (mounted) {
            setState(() {
              _reports = data['data'] ?? [];
              _isLoading = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching my reports: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
    });
    await _fetchMyReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Laporan Saya',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _reports.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada laporan',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _reports.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _reports[index];
                      Color statColor = Colors.blue;
                      if (item['status'] == 'Selesai') {
                        statColor = Colors.green;
                      } else if (item['status'] == 'Ditolak') {
                        statColor = Colors.red;
                      } else if (item['status'] == 'Menunggu') {
                        statColor = Colors.orange;
                      }

                      return _buildReportCard(
                        item['kategori_laporan'] ?? 'Laporan',
                        item['deskripsi'] ?? '-',
                        item['created_at'] != null ? item['created_at'].toString().substring(0, 10) : '-',
                        item['status'] ?? 'Menunggu',
                        statColor,
                        item['id'].toString(),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildReportCard(
    String category,
    String desc,
    String date,
    String status,
    Color statusColor,
    String reportId,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color:
                          Theme.of(context).textTheme.bodyMedium?.color ??
                          Colors.grey[800],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              desc,
              style: Theme.of(
                context,
              ).textTheme.titleMedium!.copyWith(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            Text(date, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportReceiptPage(
                        reportId: reportId,
                        category: category,
                        date: date,
                        description: desc,
                        status: status,
                        statusColor: statusColor,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long, size: 18),
                label: const Text(
                  'Lihat Struk',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
