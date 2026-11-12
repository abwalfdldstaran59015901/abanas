import 'package:flutter/material.dart';

import 'theme.dart';

/// White rounded card used across the app.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.blueLight),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: child,
    );
  }
}

class StatusChip extends StatelessWidget {
  final bool paid;
  const StatusChip({super.key, required this.paid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: paid ? AppColors.greenSoft : AppColors.redSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        paid ? 'پرداخت شده' : 'پرداخت نشده',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: paid ? AppColors.green : AppColors.red,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String text;
  const EmptyState({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, style: const TextStyle(color: AppColors.muted), textAlign: TextAlign.center),
      ),
    );
  }
}

/// Shown for sections that are built in the next phases.
class ComingSoon extends StatelessWidget {
  final String title;
  const ComingSoon({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const EmptyState(text: 'این بخش در مرحلهٔ بعد اضافه می‌شود'),
    );
  }
}
