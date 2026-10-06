import 'package:flutter/material.dart';

import '../../../core/theme/shop_owner_theme.dart';
import '../../../core/formatters.dart';
import '../../../models/shop_order.dart';
import '../../../services/shop_store.dart';
import '../dashboard/widgets/overview_grid.dart';
import '../widgets/filter_pill.dart';
import '../widgets/info_card.dart';
import '../widgets/shop_owner_app_bar.dart';

enum SalesRange {
  today('Today', 1),
  week('7 Days', 7),
  month('30 Days', 30);

  const SalesRange(this.label, this.days);

  final String label;
  final int days;
}

/// Sales Summary: what the shop earned from completed orders.
///
/// Everything is worked out from the live orders, so it needs no extra data
/// entry from the shop (NFR-06).
class SalesSummaryScreen extends StatefulWidget {
  const SalesSummaryScreen({super.key, required this.store});

  final ShopStore store;

  @override
  State<SalesSummaryScreen> createState() => _SalesSummaryScreenState();
}

class _SalesSummaryScreenState extends State<SalesSummaryScreen> {
  SalesRange _range = SalesRange.today;

  /// Midnight at the start of the first day in [range].
  DateTime _rangeStart(SalesRange range, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: range.days - 1));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, child) {
        return Scaffold(
          appBar: const DetailAppBar(title: 'Sales Summary'),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    const padding = EdgeInsets.fromLTRB(16, 4, 16, 24);
    final orders = widget.store.orders;

    if (widget.store.ordersError != null && orders == null) {
      return ListView(
        padding: padding,
        children: [InfoCard.loadError(what: 'sales')],
      );
    }
    if (orders == null) {
      return ListView(padding: padding, children: const [LoadingCard()]);
    }

    final now = DateTime.now();
    final start = _rangeStart(_range, now);

    final completed = orders
        .where(
          (order) =>
              order.status == OrderStatus.completed &&
              !order.saleDate.isBefore(start),
        )
        .toList();
    final cancelled = orders
        .where(
          (order) =>
              order.status == OrderStatus.cancelled &&
              !order.pickupTime.isBefore(start),
        )
        .length;

    final totalSales =
        completed.fold<double>(0, (sum, order) => sum + order.total);
    final average =
        completed.isEmpty ? 0.0 : totalSales / completed.length;

    return ListView(
      padding: padding,
      children: [
        // The pills sit in a row that scrolls on its own, so undo the list
        // padding to let it reach the screen edges.
        Transform.translate(
          offset: const Offset(-16, 0),
          child: FilterPillRow(
            children: [
              for (final range in SalesRange.values)
                FilterPill(
                  label: range.label,
                  selected: _range == range,
                  onTap: () => setState(() => _range = range),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        EqualHeightRow(
          children: [
            Expanded(
              child: MetricCard(
                label: 'TOTAL SALES',
                value: formatRs(totalSales),
                valueColor: ShopColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MetricCard(
                label: 'ORDERS COMPLETED',
                value: '${completed.length}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        EqualHeightRow(
          children: [
            Expanded(
              child: MetricCard(
                label: 'AVERAGE ORDER',
                value: formatRs(average),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MetricCard(
                label: 'CANCELLED',
                value: '$cancelled',
                valueColor:
                    cancelled > 0 ? ShopColors.error : ShopColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _WeekChart(orders: orders, now: now),
        const SizedBox(height: 12),
        _TopProducts(orders: completed, rangeLabel: _range.label),
        const SizedBox(height: 12),
        _PaymentSplit(orders: completed),
      ],
    );
  }
}

/// Bar chart of completed sales for each of the last 7 days.
class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.orders, required this.now});

  final List<ShopOrder> orders;
  final DateTime now;

  static const double _barAreaHeight = 96;

  @override
  Widget build(BuildContext context) {
    final today = DateTime(now.year, now.month, now.day);
    final days = [
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
    ];
    final totals = [
      for (final day in days)
        orders
            .where(
              (order) =>
                  order.status == OrderStatus.completed &&
                  isSameDay(order.saleDate, day),
            )
            .fold<double>(0, (sum, order) => sum + order.total),
    ];

    var best = 0;
    for (var i = 1; i < totals.length; i++) {
      if (totals[i] > totals[best]) best = i;
    }
    final highest = totals[best];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ShopDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last 7 Days', style: ShopText.subtitle),
          Text(
            highest <= 0
                ? 'No completed orders in the last 7 days.'
                : 'Best day: ${weekdayShort(days[best])} '
                    '${formatDayMonth(days[best])} with '
                    '${formatRs(highest)}',
            style: ShopText.body,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < days.length; i++)
                Expanded(
                  child: _Bar(
                    label: weekdayShort(days[i]),
                    amount: totals[i],
                    // Every bar is at least 4 high so empty days still show.
                    height: highest <= 0
                        ? 4.0
                        : 4.0 + (_barAreaHeight - 4) * (totals[i] / highest),
                    isToday: i == days.length - 1,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.amount,
    required this.height,
    required this.isToday,
  });

  final String label;
  final double amount;
  final double height;
  final bool isToday;

  /// 4250 -> "4.3k", 920 -> "920"
  String get _shortAmount {
    if (amount <= 0) return '';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}k';
    return amount.round().toString();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: ${formatRs(amount)}',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _shortAmount,
              style: ShopText.label.copyWith(fontSize: 10, letterSpacing: 0),
              maxLines: 1,
            ),
            const SizedBox(height: 4),
            Container(
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: isToday ? ShopColors.primary : ShopColors.greenContainer,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: ShopText.label.copyWith(
                color: isToday ? ShopColors.primary : ShopColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The five products that earned the most in the chosen range.
class _TopProducts extends StatelessWidget {
  const _TopProducts({required this.orders, required this.rangeLabel});

  final List<ShopOrder> orders;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    final revenue = <String, double>{};
    final quantity = <String, num>{};
    for (final order in orders) {
      for (final item in order.items) {
        revenue[item.name] = (revenue[item.name] ?? 0) + item.lineTotal;
        quantity[item.name] = (quantity[item.name] ?? 0) + item.quantity;
      }
    }
    final names = revenue.keys.toList()
      ..sort((a, b) => revenue[b]!.compareTo(revenue[a]!));
    final top = names.take(5).toList();
    final highest = top.isEmpty ? 0.0 : revenue[top.first]!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ShopDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Top Products', style: ShopText.subtitle),
          Text('By sales, $rangeLabel', style: ShopText.body),
          const SizedBox(height: 8),
          if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Completed orders in this period will be listed here.',
                style: ShopText.body,
              ),
            ),
          for (final name in top)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: ShopText.bodyStrong,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${formatQuantity(quantity[name] ?? 0)} sold',
                        style: ShopText.body,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        formatRs(revenue[name] ?? 0),
                        style: ShopText.bodyStrong.copyWith(
                          color: ShopColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: highest <= 0
                          ? 0.0
                          : (revenue[name] ?? 0.0) / highest,
                      minHeight: 6,
                      backgroundColor: ShopColors.surfaceMid,
                      color: ShopColors.primaryButton,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// How completed orders were paid.
class _PaymentSplit extends StatelessWidget {
  const _PaymentSplit({required this.orders});

  final List<ShopOrder> orders;

  @override
  Widget build(BuildContext context) {
    final totals = <String, double>{};
    final counts = <String, int>{};
    for (final order in orders) {
      totals[order.paymentMethod] =
          (totals[order.paymentMethod] ?? 0) + order.total;
      counts[order.paymentMethod] = (counts[order.paymentMethod] ?? 0) + 1;
    }
    final methods = totals.keys.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ShopDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Payment Methods', style: ShopText.subtitle),
          const SizedBox(height: 8),
          if (methods.isEmpty)
            Text('No completed orders in this period.', style: ShopText.body),
          for (final method in methods)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.payments_outlined,
                    size: 16,
                    color: ShopColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$method (${counts[method] ?? 0})',
                      style: ShopText.body.copyWith(
                        color: ShopColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(formatRs(totals[method] ?? 0), style: ShopText.bodyStrong),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
