import 'package:energy_tracker/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({
    required this.title,
    this.subtitle,
    this.icon = Icons.construction_rounded,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        backgroundColor: AppColors.bgDeep,
        elevation: 0,
        title: Text(title, style: AppTextStyles.titleMd),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120.r,
                height: 120.r,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 56.r,
                  color: AppColors.accent,
                ),
              ),
              SizedBox(height: 32.h),
              Text(
                'Coming Soon',
                style: AppTextStyles.titleLg.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                subtitle ??
                    'This feature is under active development.'
                        '\nStay tuned for updates!',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.text2,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48.h),
              OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.dashboard),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back to Dashboard'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text,
                  side: const BorderSide(color: AppColors.border),
                  padding:
                      EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
