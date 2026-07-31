import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  bool _showCharts = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _showCharts = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Statistik Layanan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 10),
          _buildSummaryCards(context),
          const SizedBox(height: 24),
          _buildBarChartCard(context),
          const SizedBox(height: 24),
          _buildPieChartCard(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    return Row(
      children: [
        _buildCounterCard(
          context,
          'Total Transaksi',
          1240,
          Icons.receipt_long,
          Colors.blue,
        ),
        const SizedBox(width: 16),
        _buildCounterCard(
          context,
          'Desa Mitra',
          2,
          Icons.handshake,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildCounterCard(
    BuildContext context,
    String title,
    int targetCount,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: targetCount),
              duration: const Duration(seconds: 2),
              curve: Curves.fastOutSlowIn,
              builder: (context, value, child) {
                return Text(
                  NumberFormat('#,###', 'id_ID').format(value),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grafik Penyewaan (Bulan Ini)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              duration: const Duration(seconds: 2),
              curve: Curves.fastOutSlowIn,
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 20,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        );
                        String text;
                        switch (value.toInt()) {
                          case 0:
                            text = 'Mg 1';
                            break;
                          case 1:
                            text = 'Mg 2';
                            break;
                          case 2:
                            text = 'Mg 3';
                            break;
                          case 3:
                            text = 'Mg 4';
                            break;
                          default:
                            text = '';
                            break;
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(text, style: style),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _buildAnimatedBar(0, _showCharts ? 8 : 0),
                  _buildAnimatedBar(1, _showCharts ? 10 : 0),
                  _buildAnimatedBar(2, _showCharts ? 14 : 0),
                  _buildAnimatedBar(3, _showCharts ? 15 : 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildAnimatedBar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: const LinearGradient(
            colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 20,
          borderRadius: BorderRadius.circular(6),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 20,
            color: Colors.grey.withAlpha(20),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChartCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribusi Layanan Terpopuler',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 240,
            child: PieChart(
              duration: const Duration(seconds: 2),
              curve: Curves.fastOutSlowIn,
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    color: const Color(0xFFF59E0B),
                    value: _showCharts ? 35 : 0.1,
                    title: _showCharts ? '35%' : '',
                    radius: _showCharts ? 60 : 10,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    badgeWidget: _showCharts
                        ? _buildBadge(
                            Icons.inventory_2_outlined,
                            const Color(0xFFF59E0B),
                          )
                        : const SizedBox(),
                    badgePositionPercentageOffset: 1.15,
                  ),
                  PieChartSectionData(
                    color: const Color(0xFF10B981),
                    value: _showCharts ? 25 : 0.1,
                    title: _showCharts ? '25%' : '',
                    radius: _showCharts ? 55 : 10,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    badgeWidget: _showCharts
                        ? _buildBadge(
                            Icons.propane_tank_outlined,
                            const Color(0xFF10B981),
                          )
                        : const SizedBox(),
                    badgePositionPercentageOffset: 1.15,
                  ),
                  PieChartSectionData(
                    color: const Color(0xFF0EA5E9),
                    value: _showCharts ? 25 : 0.1,
                    title: _showCharts ? '25%' : '',
                    radius: _showCharts ? 55 : 10,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    badgeWidget: _showCharts
                        ? _buildBadge(
                            Icons.directions_car_outlined,
                            const Color(0xFF0EA5E9),
                          )
                        : const SizedBox(),
                    badgePositionPercentageOffset: 1.15,
                  ),
                  PieChartSectionData(
                    color: const Color(0xFF8B5CF6),
                    value: _showCharts ? 15 : 0.1,
                    title: _showCharts ? '15%' : '',
                    radius: _showCharts ? 50 : 10,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    badgeWidget: _showCharts
                        ? _buildBadge(
                            Icons.report_gmailerrorred_outlined,
                            const Color(0xFF8B5CF6),
                          )
                        : const SizedBox(),
                    badgePositionPercentageOffset: 1.15,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              _buildLegendItem(context, const Color(0xFFF59E0B), 'Sewa Alat'),
              _buildLegendItem(context, const Color(0xFF10B981), 'Gas'),
              _buildLegendItem(context, const Color(0xFF0EA5E9), 'Mobil'),
              _buildLegendItem(context, const Color(0xFF8B5CF6), 'Laporan'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}
