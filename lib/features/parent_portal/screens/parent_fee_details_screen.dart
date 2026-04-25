import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../src/contexts/auth_controller.dart';
import '../controllers/parent_portal_controller.dart';
import '../models/parent_portal_models.dart';
import '../widgets/loading_skeletons.dart';

class ParentFeeDetailsScreen extends StatefulWidget {
  const ParentFeeDetailsScreen({super.key, required this.childId});
  final String childId;

  @override
  State<ParentFeeDetailsScreen> createState() => _ParentFeeDetailsScreenState();
}

class _ParentFeeDetailsScreenState extends State<ParentFeeDetailsScreen> {
  ChildDetailData? _childDetail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthController>();
    final controller = context.read<ParentPortalController>();
    final cId = int.tryParse(widget.childId);
    if (cId == null || auth.currentUser == null) return;

    try {
      final detail = await controller.loadChildDetail(
        user: auth.currentUser!,
        childId: cId,
      );
      if (mounted) {
        setState(() {
          _childDetail = detail;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fee Details')),
        body: const DashboardLoadingSkeleton(),
      );
    }

    if (_childDetail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fee Details')),
        body: const Center(child: Text('Failed to load fee details.')),
      );
    }

    final fees = _childDetail!.feeHistory;
    
    double totalPaid = 0;
    double totalPending = 0;
    
    for (final fee in fees) {
      if (fee.status == FeeStatusType.paid) {
        totalPaid += fee.amount;
      } else {
        totalPending += fee.amount;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Details'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildChart(totalPaid, totalPending),
            const SizedBox(height: 24),
            Text('Transaction History', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (fees.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No fee records.')))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: fees.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final fee = fees[index];
                  
                  Color statusColor = Colors.green;
                  String statusText = 'PAID';
                  if (fee.status == FeeStatusType.overdue) {
                    statusColor = Colors.red;
                    statusText = 'OVERDUE';
                  } else if (fee.status == FeeStatusType.pending) {
                    statusColor = Colors.orange;
                    statusText = 'PENDING';
                  }

                  return ListTile(
                    tileColor: const Color(0x331A1412),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    title: Text('₹${fee.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text('Due: ${fee.dueDate.toLocal().toString().split(' ')[0]}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(double paid, double pending) {
    if (paid == 0 && pending == 0) return const SizedBox();

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x801A1412),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1AFFFFFF), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    color: Colors.green,
                    value: paid,
                    title: '',
                    radius: 30,
                  ),
                  PieChartSectionData(
                    color: Colors.orange,
                    value: pending,
                    title: '',
                    radius: 30,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegend('Paid', paid, Colors.green),
              const SizedBox(height: 16),
              _buildLegend('Pending', pending, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, double amount, Color color) {
    return Row(
      children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ],
    );
  }
}
