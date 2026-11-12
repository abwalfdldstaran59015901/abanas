import 'package:flutter/material.dart';

import '../../api.dart';
import '../../format.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets.dart';
import '../login_screen.dart';

/// Admin panel: list of buildings with the manager access switch.
class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _index = 0;
  List<Map<String, dynamic>> _buildings = [];
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
      final rows = await rpc('admin_buildings_full', {'p_admin_key': appState.adminKey}) as List;
      setState(() => _buildings = rows.cast<Map<String, dynamic>>());
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(Map<String, dynamic> b) async {
    final active = b['is_active'] == true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(active ? 'دسترسی مدیر این ساختمان قطع شود؟' : 'دسترسی مدیر فعال شود؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تأیید')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await rpc('admin_set_building_access', {
        'p_admin_key': appState.adminKey,
        'p_code': b['code'],
        'p_active': !active,
      });
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _logout() {
    appState.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Widget _buildingsView() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return EmptyState(text: _error!);
    if (_buildings.isEmpty) return const EmptyState(text: 'ساختمانی ثبت نشده است');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _buildings.map((b) {
          final active = b['is_active'] == true;
          final plan = b['plan']?.toString() ?? 'normal';
          final planText = plan == 'free' ? 'رایگان' : (plan == 'half' ? 'نیم‌بها' : 'عادی');
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('${b['code']} · ${b['city'] ?? ''}',
                            style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('طرح: $planText · معرفی: ${fmtNum((b['referral_count'] ?? 0) as num)}',
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  Switch(value: active, onChanged: (_) => _toggle(b)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _buildingsView(),
      const ComingSoon(title: 'اعلان‌ها'),
      const ComingSoon(title: 'پیام‌های پشتیبانی'),
      const ComingSoon(title: 'ثبت ساختمان'),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('پنل ادمین'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout, color: AppColors.red), tooltip: 'خروج'),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.apartment_outlined), selectedIcon: Icon(Icons.apartment), label: 'ساختمان‌ها'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'اعلان‌ها'),
          NavigationDestination(icon: Icon(Icons.support_agent_outlined), selectedIcon: Icon(Icons.support_agent), label: 'پشتیبانی'),
          NavigationDestination(icon: Icon(Icons.add_business_outlined), selectedIcon: Icon(Icons.add_business), label: 'ثبت ساختمان'),
        ],
      ),
    );
  }
}
