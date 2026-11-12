import 'package:flutter/material.dart';

import '../api.dart';
import '../state.dart';
import '../theme.dart';
import 'admin/admin_home.dart';
import 'manager/manager_home.dart';
import 'resident/resident_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _role = 'manager';
  bool _busy = false;
  String? _error;

  final _building = TextEditingController();
  final _password = TextEditingController();
  final _unit = TextEditingController();
  final _check = TextEditingController();
  final _adminKey = TextEditingController();

  @override
  void dispose() {
    for (final c in [_building, _password, _unit, _check, _adminKey]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_role == 'manager') {
        final rows = await rpc('manager_login', {
          'p_building': _building.text.trim(),
          'p_password': _password.text,
        }) as List;
        final r = rows.first as Map<String, dynamic>;
        appState.managerToken = r['token'].toString();
        appState.managerBuildingName = r['building_name'].toString();
        _go(const ManagerHome());
      } else if (_role == 'resident') {
        final params = {
          'p_building': _building.text.trim(),
          'p_unit': _unit.text.trim(),
          'p_check': _check.text.trim().isEmpty ? null : _check.text.trim(),
        };
        // this call checks the building, unit and access code
        await rpc('get_unit_history', params);
        appState.residentBuilding = params['p_building'] as String;
        appState.residentUnit = params['p_unit'] as String;
        appState.residentCheck = params['p_check'] as String?;
        _go(const ResidentHome());
      } else {
        await rpc('admin_login', {'p_admin_key': _adminKey.text});
        appState.adminKey = _adminKey.text;
        _go(const AdminHome());
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'ورود انجام نشد؛ دوباره تلاش کنید');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _go(Widget page) {
    _password.clear();
    _adminKey.clear();
    _check.clear();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Image.asset('assets/logo.png', width: 110, height: 110),
                  const SizedBox(height: 8),
                  const Text('ورود به سامانه',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text)),
                  const SizedBox(height: 18),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'manager', label: Text('مدیر')),
                      ButtonSegment(value: 'resident', label: Text('ساکن')),
                      ButtonSegment(value: 'admin', label: Text('ادمین')),
                    ],
                    selected: {_role},
                    onSelectionChanged: (s) => setState(() {
                      _role = s.first;
                      _error = null;
                    }),
                  ),
                  const SizedBox(height: 18),
                  if (_role == 'manager') ...[
                    _field(_building, 'نام یا کد ساختمان'),
                    _field(_password, 'رمز مدیر', obscure: true),
                  ],
                  if (_role == 'resident') ...[
                    _field(_building, 'نام یا کد ساختمان'),
                    _field(_unit, 'شماره واحد'),
                    _field(_check, 'کد تأیید واحد'),
                  ],
                  if (_role == 'admin') _field(_adminKey, 'کلید ثبت ساختمان', obscure: true),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_error!, style: const TextStyle(color: AppColors.red)),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: AppColors.blue,
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('ورود', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
