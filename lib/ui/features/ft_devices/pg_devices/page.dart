import 'dart:async';

import 'package:energy_tracker/app.dart';
import 'package:energy_tracker/services/notifier/user_profile_notifier.dart';
import 'package:energy_tracker/ui/features/ft_devices/pg_devices/notifier/notifier.dart';
import 'package:energy_tracker/ui/features/ft_devices/pg_devices/widgets/devices_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class DevicesPage extends ConsumerWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      devicesProvider.select((value) => value.isLoading),
    );
    final errorMessage = ref.watch(
      devicesProvider.select((value) => value.errorMessage),
    );
    final isEmpty = ref.watch(
      devicesProvider.select((value) => value.appliances.isEmpty),
    );

    return ColoredBox(
      color: AppColors.bg,
      child: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: isLoading && isEmpty
                  ? const DevicesSkeleton()
                  : errorMessage != null
                  ? ErrorView(
                      message: errorMessage,
                      onRetry: () =>
                          ref.read(devicesProvider.notifier).refresh(),
                    )
                  : isEmpty
                  ? const _EmptyDevicesView()
                  : const _BodyContent(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.screenPaddingH,
        12.h,
        AppDimensions.screenPaddingH,
        16.h,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('My Appliances', style: AppTextStyles.titleMd),
          GestureDetector(
            onTap: () => context.push(AppRoutes.addAppliance),
            child: Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Icon(
                Icons.add_rounded,
                size: 20.r,
                color: AppColors.onAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ApplianceSort { cost, name, hours }

class _BodyContent extends ConsumerStatefulWidget {
  const _BodyContent();

  @override
  ConsumerState<_BodyContent> createState() => _BodyContentState();
}

class _BodyContentState extends ConsumerState<_BodyContent>
    with WidgetsBindingObserver {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _keyboardWasVisible = false;
  Timer? _keyboardHideTimer;
  String _query = '';
  String _category = 'All';
  _ApplianceSort _sort = _ApplianceSort.cost;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _keyboardHideTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final bottom = View.of(context).viewInsets.bottom;
    if (bottom > 0) {
      _keyboardHideTimer?.cancel();
      _keyboardWasVisible = true;
      return;
    }

    // Debounce the close so an inset flicker while the keyboard opens cannot
    // immediately steal focus back from the search field.
    if (_keyboardWasVisible && _searchFocusNode.hasFocus) {
      _keyboardWasVisible = false;
      _keyboardHideTimer?.cancel();
      _keyboardHideTimer = Timer(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        if (View.of(context).viewInsets.bottom == 0 &&
            _searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
        }
      });
    }
  }

  List<Appliance> _visibleAppliances(List<Appliance> all) {
    final query = _query.trim().toLowerCase();
    final filtered = all.where((appliance) {
      final matchesQuery =
          query.isEmpty ||
          appliance.name.toLowerCase().contains(query) ||
          appliance.category.toLowerCase().contains(query);
      final matchesCategory =
          _category == 'All' || appliance.category == _category;
      return matchesQuery && matchesCategory;
    }).toList();

    switch (_sort) {
      case _ApplianceSort.cost:
        filtered.sort((a, b) => b.monthlyCost().compareTo(a.monthlyCost()));
      case _ApplianceSort.name:
        filtered.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case _ApplianceSort.hours:
        filtered.sort((a, b) => b.dailyHours.compareTo(a.dailyHours));
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(devicesProvider.select((s) => s.appliances));
    final categories = all.map((a) => a.category).toSet().toList()..sort();
    final visible = _visibleAppliances(all);
    final showFilters = all.isNotEmpty;

    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.surface2,
      onRefresh: () => ref.read(devicesProvider.notifier).refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppDimensions.screenPaddingH,
              4.h,
              AppDimensions.screenPaddingH,
              0,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _SummaryCard(),
                SizedBox(height: 12.h),
                const _InsightsSection(),
                if (showFilters) ...[
                  SizedBox(height: 16.h),
                  _SearchField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (value) => setState(() => _query = value),
                    onClear: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
                  SizedBox(height: 12.h),
                  _CategoryFilters(
                    categories: categories,
                    selected: _category,
                    onSelected: (value) => setState(() => _category = value),
                  ),
                ],
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Appliances (${visible.length})',
                        style: AppTextStyles.bodyMd.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (showFilters)
                      _SortButton(
                        sort: _sort,
                        onSelected: (value) => setState(() => _sort = value),
                      ),
                  ],
                ),
                SizedBox(height: 8.h),
              ]),
            ),
          ),
          if (visible.isEmpty)
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPaddingH,
              ),
              sliver: const SliverToBoxAdapter(
                child: _NoFilterResults(),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPaddingH,
              ),
              sliver: SliverList.builder(
                itemCount: visible.length,
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: _ApplianceRow(appliance: visible[index]),
                ),
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: 24.h)),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: (_) => focusNode.unfocus(),
      onTapOutside: (_) => focusNode.unfocus(),
      textInputAction: TextInputAction.search,
      style: AppTextStyles.bodyMd,
      decoration: InputDecoration(
        hintText: 'Search appliances',
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 18.r,
          color: AppColors.text3,
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                tooltip: 'Clear search',
                icon: Icon(
                  Icons.close_rounded,
                  size: 18.r,
                  color: AppColors.text3,
                ),
              ),
        filled: true,
        fillColor: AppColors.surface2,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12.w,
          vertical: 10.h,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
    );
  }
}

class _CategoryFilters extends StatelessWidget {
  const _CategoryFilters({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FilterChip(
            label: 'All',
            selected: selected == 'All',
            onTap: () => onSelected('All'),
          ),
          for (final category in categories) ...[
            SizedBox(width: 6.w),
            _FilterChip(
              label: category,
              selected: selected == category,
              onTap: () => onSelected(category),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 48.r, minHeight: 48.r),
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.accent.withValues(alpha: 0.14)
                  : AppColors.surface2,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.border,
              ),
            ),
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: selected ? AppColors.accent : AppColors.text2,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                height: 1.15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.sort, required this.onSelected});

  final _ApplianceSort sort;
  final ValueChanged<_ApplianceSort> onSelected;

  String get _label {
    switch (sort) {
      case _ApplianceSort.cost:
        return 'Cost';
      case _ApplianceSort.name:
        return 'A?Z';
      case _ApplianceSort.hours:
        return 'Hours';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ApplianceSort>(
      onSelected: onSelected,
      tooltip: 'Sort appliances',
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _ApplianceSort.cost,
          child: Text('Cost: high to low'),
        ),
        PopupMenuItem(value: _ApplianceSort.name, child: Text('Name: A to Z')),
        PopupMenuItem(
          value: _ApplianceSort.hours,
          child: Text('Hours: high to low'),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.swap_vert_rounded,
            size: 16.r,
            color: AppColors.text2,
          ),
          SizedBox(width: 4.w),
          Text(
            _label,
            style: AppTextStyles.caption.copyWith(color: AppColors.text2),
          ),
        ],
      ),
    );
  }
}

class _NoFilterResults extends StatelessWidget {
  const _NoFilterResults();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        'No appliances match your filters.',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySm.copyWith(color: AppColors.text2),
      ),
    );
  }
}

class _InsightsSection extends StatefulWidget {
  const _InsightsSection();

  @override
  State<_InsightsSection> createState() => _InsightsSectionState();
}

class _InsightsSectionState extends State<_InsightsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(color: AppColors.border),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: EdgeInsets.all(12.r),
              child: Row(
                children: [
                  Icon(
                    Icons.insights_rounded,
                    size: 18.r,
                    color: AppColors.accent,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Insights',
                          style: AppTextStyles.bodySm.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Biggest consumers and category breakdown',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.text3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18.r,
                    color: AppColors.text3,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 14.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(height: 1, color: AppColors.border),
                        SizedBox(height: 12.h),
                        const _BiggestConsumersCard(embedded: true),
                        SizedBox(height: 16.h),
                        const _CategoryBreakdownCard(embedded: true),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _EmptyDevicesView extends StatelessWidget {
  const _EmptyDevicesView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.r,
              height: 72.r,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Icon(
                Icons.power_outlined,
                size: 32.r,
                color: AppColors.accent,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'No appliances yet',
              style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8.h),
            Text(
              'Add your appliances to see how much\neach one costs monthly.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm,
            ),
            SizedBox(height: 24.h),
            GestureDetector(
              onTap: () => context.push(AppRoutes.addAppliance),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accent, AppColors.accent2],
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Text(
                  'Add First Appliance',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onAccent,
                    fontWeight: FontWeight.w700,
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

class _BiggestConsumersCard extends ConsumerWidget {
  const _BiggestConsumersCard({this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appliances = ref.watch(
      devicesProvider.select((s) => s.appliancesByCost),
    );
    final total = ref.watch(
      devicesProvider.select((s) => s.totalMonthlyCost),
    );
    if (appliances.isEmpty || total <= 0) return const SizedBox.shrink();

    final top = appliances.take(3).toList();
    return _InsightCard(
      title: 'Biggest consumers',
      subtitle: 'Top 3 highest estimated costs',
      embedded: embedded,
      children: [
        for (var i = 0; i < top.length; i++)
          _ConsumerRow(
            rank: i + 1,
            appliance: top[i],
            fraction: top[i].monthlyCost() / total,
          ),
      ],
    );
  }
}

class _ConsumerRow extends StatelessWidget {
  const _ConsumerRow({
    required this.rank,
    required this.appliance,
    required this.fraction,
  });

  final int rank;
  final Appliance appliance;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 18.w,
                child: Text(
                  '$rank',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.text3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                appliance.categoryEmoji,
                style: TextStyle(fontSize: 13.sp),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  appliance.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '~RM ${appliance.monthlyCost().toStringAsFixed(0)}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.text2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 5.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(3.r),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 5.h,
              backgroundColor: AppColors.surface3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBreakdownCard extends ConsumerWidget {
  const _CategoryBreakdownCard({this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final costs = ref.watch(
      devicesProvider.select((s) => s.categoryMonthlyCost),
    );
    final total = ref.watch(
      devicesProvider.select((s) => s.totalMonthlyCost),
    );
    if (costs.isEmpty || total <= 0) return const SizedBox.shrink();

    final entries = costs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _InsightCard(
      title: 'By category',
      subtitle: 'Estimated monthly cost',
      embedded: embedded,
      children: [
        for (final entry in entries)
          _CategoryRow(
            category: entry.key,
            cost: entry.value,
            fraction: entry.value / total,
          ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.cost,
    required this.fraction,
  });

  final String category;
  final double cost;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 9.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                Appliance.emojiForCategory(category),
                style: TextStyle(fontSize: 13.sp),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  category,
                  style: AppTextStyles.bodySm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '~RM ${cost.toStringAsFixed(0)}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.text2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(3.r),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 4.h,
              backgroundColor: AppColors.surface3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent2),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.subtitle,
    required this.children,
    this.embedded = false,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bodySm.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          subtitle,
          style: AppTextStyles.caption.copyWith(color: AppColors.text3),
        ),
        SizedBox(height: 10.h),
        ...children,
      ],
    );

    if (embedded) return content;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: content,
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applianceCount = ref.watch(
      devicesProvider.select((s) => s.appliances.length),
    );
    final totalCost = ref.watch(
      devicesProvider.select((s) => s.totalMonthlyCost),
    );
    final lowCost = ref.watch(
      devicesProvider.select((s) => s.estimatedLowMonthlyCost),
    );
    final highCost = ref.watch(
      devicesProvider.select((s) => s.estimatedHighMonthlyCost),
    );
    final monthlyBudget = ref.watch(
      userProfileProvider.select((p) => p.profile?.monthlyBudget ?? 0),
    );
    final budgetSuffix = monthlyBudget > 0
        ? ' \u00b7 ~${(totalCost / monthlyBudget * 100).toStringAsFixed(0)}% '
              'of RM ${monthlyBudget.toStringAsFixed(0)} budget'
        : '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.14),
            AppColors.accent2.withValues(alpha: 0.07),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estimated monthly cost',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.text2,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            '~RM ${totalCost.toStringAsFixed(0)}',
            style: AppTextStyles.displayLg.copyWith(
              color: AppColors.accent,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Range ~RM ${lowCost.toStringAsFixed(0)}\u2013'
            '${highCost.toStringAsFixed(0)}',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.text2,
            ),
          ),
          SizedBox(height: 10.h),
          Divider(height: 1, color: AppColors.border),
          SizedBox(height: 8.h),
          Text(
            '$applianceCount appliance${applianceCount == 1 ? '' : 's'}'
            '$budgetSuffix',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.text2,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'Tracked appliances only \u00b7 not your TNB bill',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.text3,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplianceRow extends ConsumerWidget {
  const _ApplianceRow({required this.appliance});

  final Appliance appliance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hours = appliance.dailyHours % 1 == 0
        ? appliance.dailyHours.toInt().toString()
        : appliance.dailyHours.toStringAsFixed(1);

    return Dismissible(
      key: Key(appliance.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: AppColors.danger,
          size: 22.r,
        ),
      ),
      confirmDismiss: (_) async {
        final confirmed = await _confirmDelete(context) ?? false;
        if (!confirmed) return false;
        return ref.read(devicesProvider.notifier).deleteAppliance(appliance.id);
      },
      child: Semantics(
        button: true,
        label:
            '${appliance.name}, estimated RM '
            '${appliance.monthlyCost().toStringAsFixed(0)} per month',
        child: GestureDetector(
          onTap: () =>
              context.push(AppRoutes.applianceDetail, extra: appliance),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                  child: Center(
                    child: Text(
                      appliance.categoryEmoji,
                      style: TextStyle(fontSize: 17.sp),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appliance.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMd.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '~${hours}h/day \u00b7 ${appliance.category}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.text3,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '~RM ${appliance.monthlyCost().toStringAsFixed(0)}',
                  style: AppTextStyles.bodySm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16.r,
                  color: AppColors.text3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        title: Text(
          'Delete Appliance',
          style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Delete "${appliance.name}" from your list?',
          style: AppTextStyles.bodySm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.text2),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
