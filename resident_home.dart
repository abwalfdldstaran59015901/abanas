import 'package:flutter/material.dart';

import '../../api.dart';
import '../../format.dart';
import '../../models.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets.dart';
import '../login_screen.dart';

/// Resident panel: all bills of the unit and the total debt.
class ResidentHome extends StatefulWidget {
  const ResidentHome({super.key});

  @override
  State<ResidentHome> createState() => _ResidentHomeState();
}

class _ResidentHomeState extends State<ResidentHome> {
  List<BillRow> _bills = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await rpc('get_unit_history', {
        'p_building': appState.residentBuilding,
        'p_unit': appState.residentUnit,
        'p_check': appState.residentCheck,
      }) as List;
      setState(() => _bills = rows.map((r) => BillRow.fromJson(r as Map<String, dynamic>)).toList());
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _logout() {
    appState.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final debt = _bills.where((b) => !b.isPaid).fold<num>(0, (s, b) => s + b.balance);
    final unpaidCount = _bills.where((b) => !b.isPaid).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('واحد ${appState.residentUnit ?? ''}'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout, color: AppColors.red), tooltip: 'خروج'),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? EmptyState(text: _error!)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.blue, AppColors.navy]),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('مجموع بدهی', style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 6),
                            Text(fmtMoney(debt),
                                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(
                              unpaidCount == 0 ? 'همه قبض‌ها پرداخت شده است' : '${fmtNum(unpaidCount)} قبض پرداخت نشده',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text('قبض‌های صادرشده', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 10),
                      if (_bills.isEmpty) const EmptyState(text: 'هنوز قبضی صادر نشده است'),
                      ..._bills.map((b) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(b.periodTitle,
                                            style: const TextStyle(fontWeight: FontWeight.w700)),
                                      ),
                                      StatusChip(paid: b.isPaid),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _line('مبلغ قبض', fmtMoney(b.amountDue)),
                                  _line('پرداختی', fmtMoney(b.paidAmount)),
                                  _line('مانده', fmtMoney(b.balance)),
                                  _line('مهلت پرداخت', fmtJalali(b.dueDate)),
                                  if (b.verificationCode != null)
                                    _line('کد تأیید', b.verificationCode!),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
