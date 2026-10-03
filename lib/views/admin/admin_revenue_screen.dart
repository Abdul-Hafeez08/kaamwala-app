import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../models/job_model.dart';

class AdminRevenueScreen extends StatefulWidget {
  const AdminRevenueScreen({super.key});

  @override
  State<AdminRevenueScreen> createState() => _AdminRevenueScreenState();
}

class _AdminRevenueScreenState extends State<AdminRevenueScreen> {
  String _timeframe = 'Monthly';
  List<JobModel> _completedJobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCompletedJobs();
  }

  Future<void> _fetchCompletedJobs() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('jobs')
          .where('status', isEqualTo: 'completed')
          .get();

      final jobs = snapshot.docs.map((d) => JobModel.fromMap(d.data())).toList();
      setState(() {
        _completedJobs = jobs;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading revenue data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _totalRevenue {
    return _completedJobs.fold(0.0, (sum, job) => sum + job.price);
  }

  Map<String, double> _getWorkerRevenue() {
    final map = <String, double>{};
    for (var job in _completedJobs) {
      final name = job.workerName.isEmpty ? 'Unknown' : job.workerName;
      map[name] = (map[name] ?? 0.0) + job.price;
    }
    return map;
  }

  Map<int, double> _getTimeframeRevenue() {
    final map = <int, double>{};
    final now = DateTime.now();

    for (var job in _completedJobs) {
      final date = job.completedAt ?? job.scheduledDate;
      if (_timeframe == 'Weekly') {
        // Last 7 days
        final diff = now.difference(date).inDays;
        if (diff <= 7 && diff >= 0) {
          map[7 - diff] = (map[7 - diff] ?? 0.0) + job.price;
        }
      } else if (_timeframe == 'Monthly') {
        // Last 30 days, grouped by week (1-4) or just 4 weeks
        if (date.year == now.year && date.month == now.month) {
          final weekNum = ((date.day - 1) / 7).floor() + 1;
          map[weekNum] = (map[weekNum] ?? 0.0) + job.price;
        }
      } else if (_timeframe == 'Yearly') {
        // Group by month
        if (date.year == now.year) {
          map[date.month] = (map[date.month] ?? 0.0) + job.price;
        }
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revenue Analytics', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          DropdownButton<String>(
            value: _timeframe,
            underline: const SizedBox(),
            items: ['Weekly', 'Monthly', 'Yearly'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() => _timeframe = newValue);
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _completedJobs.isEmpty
              ? const Center(child: Text('No completed jobs yet.'))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 800;
                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total Revenue Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Gross Revenue',
                              style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              NumberFormat.currency(symbol: 'Rs. ').format(_totalRevenue),
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      isWide ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Revenue Trend ($_timeframe)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                SizedBox(height: 300, child: _buildTemporalChart(isDark)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Revenue by Worker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 16),
                                SizedBox(height: 300, child: _buildWorkerChart(isDark)),
                              ],
                            ),
                          ),
                        ],
                      ) : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Revenue Trend ($_timeframe)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          SizedBox(height: 250, child: _buildTemporalChart(isDark)),
                          const SizedBox(height: 40),
                          const Text('Revenue by Worker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          SizedBox(height: 300, child: _buildWorkerChart(isDark)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildTemporalChart(bool isDark) {
    final data = _getTimeframeRevenue();
    if (data.isEmpty) return const Center(child: Text('No data for this timeframe'));

    final spots = <FlSpot>[];
    double maxRevenue = 0;

    int minX = 1;
    int maxX = 1;

    if (_timeframe == 'Weekly') {
      minX = 1; maxX = 7;
    } else if (_timeframe == 'Monthly') {
      minX = 1; maxX = 5;
    } else if (_timeframe == 'Yearly') {
      minX = 1; maxX = 12;
    }

    for (int i = minX; i <= maxX; i++) {
      final val = data[i] ?? 0.0;
      if (val > maxRevenue) maxRevenue = val;
      spots.add(FlSpot(i.toDouble(), val));
    }

    return LineChart(
      LineChartData(
        minX: minX.toDouble(),
        maxX: maxX.toDouble(),
        minY: 0,
        maxY: maxRevenue * 1.2 == 0 ? 100 : maxRevenue * 1.2,
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (_timeframe == 'Weekly') {
                  return Padding(padding: const EdgeInsets.only(top: 8), child: Text('Day ${value.toInt()}'));
                } else if (_timeframe == 'Monthly') {
                  return Padding(padding: const EdgeInsets.only(top: 8), child: Text('W${value.toInt()}'));
                } else {
                  return Padding(padding: const EdgeInsets.only(top: 8), child: Text('${value.toInt()}'));
                }
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFFFF9800),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFFFF9800).withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerChart(bool isDark) {
    final data = _getWorkerRevenue();
    if (data.isEmpty) return const Center(child: Text('No worker revenue data'));

    final entries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topWorkers = entries.take(5).toList();

    double maxRevenue = 0;
    for (var w in topWorkers) {
      if (w.value > maxRevenue) maxRevenue = w.value;
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxRevenue * 1.2 == 0 ? 100 : maxRevenue * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${topWorkers[group.x].key}\nRs. ${rod.toY.toInt()}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, _) {
                if (value.toInt() >= topWorkers.length) return const SizedBox();
                final name = topWorkers[value.toInt()].key;
                final shortName = name.length > 8 ? '${name.substring(0, 6)}..' : name;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    shortName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(
          topWorkers.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: topWorkers[i].value,
                color: const Color(0xFFFF9800),
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          ),
        ).toList(),
      ),
    );
  }
}
