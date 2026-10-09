import 'package:flutter/material.dart';

import '../../../core/theme/shop_owner_theme.dart';
import '../../../core/formatters.dart';
import '../../../models/shop_order.dart';
import '../../../services/shop_store.dart';
import '../shop_actions.dart';
import '../widgets/button_spinner.dart';
import '../widgets/info_card.dart';
import '../widgets/shop_owner_app_bar.dart';
import '../widgets/status_pill.dart';

/// Shop Order Details & Status Update.
///
/// Shows one order live, so it updates by itself if the status changes
/// elsewhere. The bottom bar always holds the next step:
///   New        -> Reject / Start Preparing
///   Preparing  -> Mark as Ready for Pickup (notifies the customer, FR-07)
///   Ready      -> Mark as Completed
class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({
    super.key,
    required this.store,
    required this.actions,
    required this.orderId,
  });

  final ShopStore store;
  final ShopActions actions;
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, child) {
        final order = store.orderById(orderId);

        return Scaffold(
          appBar: const DetailAppBar(title: 'Order Details'),
          body: order == null
              ? ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (store.orders == null)
                      const LoadingCard()
                    else
                      const InfoCard(
                        icon: Icons.search_off,
                        title: 'Order not found',
                        message: 'This order is no longer available.',
                      ),
                  ],
                )
              : _buildBody(context, order),
          bottomNavigationBar:
              order == null ? null : _buildBottomBar(context, order),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ShopOrder order) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _HeaderCard(order: order),
        const SizedBox(height: 12),
        _CustomerCard(
          order: order,
          onCall: () => actions.callCustomer(context, order.customerPhone),
        ),
        const SizedBox(height: 12),
        if (order.status == OrderStatus.cancelled)
          _CancelledCard(order: order)
        else
          _PipelineCard(status: order.status),
        const SizedBox(height: 12),
        _ChecklistCard(
          order: order,
          onToggle: (index, packed) =>
              actions.setItemPacked(order, index, packed),
        ),
      ],
    );
  }

  Widget? _buildBottomBar(BuildContext context, ShopOrder order) {
    final busy = store.isBusy(order.id);
    final List<Widget> buttons;

    if (order.status == OrderStatus.newOrder) {
      buttons = [
        SizedBox(
          height: 48,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: ShopColors.error,
              side: const BorderSide(color: ShopColors.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: ShopText.button,
            ),
            onPressed: busy ? null : () => actions.rejectOrder(context, order),
            child: const Text('Reject'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _BottomButton(
            label: 'Start Preparing',
            icon: Icons.inventory_2_outlined,
            color: ShopColors.primaryButton,
            busy: busy,
            onPressed: () => actions.startPreparing(context, order),
          ),
        ),
      ];
    } else if (order.status == OrderStatus.preparing) {
      buttons = [
        Expanded(
          child: _BottomButton(
            label: 'Mark as Ready for Pickup',
            icon: Icons.check_circle_outline,
            color: ShopColors.primary,
            busy: busy,
            onPressed: () => actions.markReady(context, order),
          ),
        ),
      ];
    } else if (order.status == OrderStatus.ready) {
      buttons = [
        Expanded(
          child: _BottomButton(
            label: 'Mark as Completed',
            icon: Icons.task_alt,
            color: ShopColors.primary,
            busy: busy,
            onPressed: () => actions.completeOrder(context, order),
          ),
        ),
      ];
    } else {
      // Completed and cancelled orders have no next step.
      return null;
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ShopColors.background,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F1B5E20),
            offset: Offset(0, -2),
            blurRadius: 12,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: buttons),
        ),
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  const _BottomButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton(
        style: ShopDecor.primaryButton(color: color),
        onPressed: busy ? null : onPressed,
        child: busy
            ? const ButtonSpinner()
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Order number, when it was placed and the pickup time.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.order});

  final ShopOrder order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ShopDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${order.orderNumber}',
                  style: ShopText.title,
                ),
              ),
              StatusPill(status: order.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Placed ${formatPickupSlot(order.createdAt)}',
            style: ShopText.label,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: ShopColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Pick Up Time: ${formatPickupSlot(order.pickupTime)}',
                  style: ShopText.body,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Customer name and phone with a call button.
class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.order, required this.onCall});

  final ShopOrder order;
  final VoidCallback onCall;

  /// "Sanduni Perera" -> "SP"
  String get _initials {
    final parts = order.customerName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasPhone = order.customerPhone.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ShopDecor.card(),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: ShopColors.surfaceHigh,
                child: Text(
                  _initials,
                  style: ShopText.subtitle.copyWith(color: ShopColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.customerName, style: ShopText.subtitle),
                    if (hasPhone)
                      Text(order.customerPhone, style: ShopText.body),
                  ],
                ),
              ),
              if (hasPhone)
                Tooltip(
                  message: 'Call ${order.customerName}',
                  child: Material(
                    color: ShopColors.surfaceMid,
                    borderRadius: BorderRadius.circular(8),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: onCall,
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.call,
                          size: 20,
                          color: ShopColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: ShopDecor.tile(),
            child: Row(
              children: [
                const Icon(
                  Icons.storefront_outlined,
                  size: 16,
                  color: ShopColors.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Pickup Scheduled', style: ShopText.bodyStrong),
                ),
                Text(
                  formatPickupSlot(order.pickupTime),
                  style: ShopText.bodyStrong.copyWith(color: ShopColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The four-step progress row: Received, Packing, Ready, Done.
class _PipelineCard extends StatelessWidget {
  const _PipelineCard({required this.status});

  final OrderStatus status;

  static const List<String> _labels = ['Received', 'Packing', 'Ready', 'Done'];
  static const List<IconData> _icons = [
    Icons.check,
    Icons.inventory_2_outlined,
    Icons.shopping_bag_outlined,
    Icons.task_alt,
  ];

  /// Position of the current step, counting from 0.
  int get _currentStep {
    switch (status) {
      case OrderStatus.newOrder:
        return 0;
      case OrderStatus.preparing:
        return 1;
      case OrderStatus.ready:
        return 2;
      case OrderStatus.completed:
      case OrderStatus.cancelled:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentStep;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ShopDecor.card(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'LIVE PIPELINE',
                  style: ShopText.caps.copyWith(color: ShopColors.textPrimary),
                ),
              ),
              Text(
                'Step ${current + 1} of ${_labels.length}',
                style: ShopText.label.copyWith(color: ShopColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < _labels.length; i++)
                Expanded(
                  child: _PipelineStep(
                    label: _labels[i],
                    icon: _icons[i],
                    reached: i <= current,
                    isCurrent: i == current,
                    lineBefore: i == 0 ? null : i <= current,
                    lineAfter: i == _labels.length - 1 ? null : i < current,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PipelineStep extends StatelessWidget {
  const _PipelineStep({
    required this.label,
    required this.icon,
    required this.reached,
    required this.isCurrent,
    required this.lineBefore,
    required this.lineAfter,
  });

  final String label;
  final IconData icon;

  /// This step is done or in progress.
  final bool reached;
  final bool isCurrent;

  /// Whether the connecting line on each side is green. Null means the step
  /// is at the end of the row and has no line on that side.
  final bool? lineBefore;
  final bool? lineAfter;

  Widget _line(bool? filled) {
    return Expanded(
      child: Container(
        height: 2,
        color: filled == null
            ? Colors.transparent
            : (filled ? ShopColors.primary : ShopColors.surfaceHigh),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _line(lineBefore),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: reached ? ShopColors.primary : ShopColors.surfaceHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 16,
                color: reached ? Colors.white : ShopColors.textSecondary,
              ),
            ),
            _line(lineAfter),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: ShopText.label.copyWith(
            color: isCurrent
                ? ShopColors.primary
                : (reached ? ShopColors.textPrimary : ShopColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// Replaces the pipeline for an order the shop rejected.
class _CancelledCard extends StatelessWidget {
  const _CancelledCard({required this.order});

  final ShopOrder order;

  @override
  Widget build(BuildContext context) {
    final reason = order.cancelReason;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ShopColors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cancel_outlined, size: 20, color: ShopColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.cancelledByCustomer
                      ? 'Order cancelled by the customer'
                      : 'Order cancelled',
                  style: ShopText.subtitle.copyWith(
                    color: ShopColors.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order.cancelledByCustomer
                      ? ((reason == null || reason.isEmpty)
                          ? '${order.customerName} cancelled this order. No need to prepare it.'
                          : '${order.customerName} cancelled this order. Reason: $reason.')
                      : (reason == null || reason.isEmpty)
                          ? 'The customer was told this order was cancelled.'
                          : 'Reason: $reason. The customer was told.',
                  style: ShopText.body.copyWith(color: ShopColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Order Packing Checklist with payment method and total underneath.
class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({required this.order, required this.onToggle});

  final ShopOrder order;
  final void Function(int index, bool packed) onToggle;

  @override
  Widget build(BuildContext context) {
    // Items can only be ticked while the order is being prepared.
    final canTick = order.status == OrderStatus.preparing;
    final allDone = order.status == OrderStatus.ready ||
        order.status == OrderStatus.completed;

    // Some orders arrive with only a text summary of their items. They are
    // shown as that summary, without a checklist.
    final hasList = order.hasItemList;

    var hint = '';
    if (!hasList) {
      hint = 'This order came without an item-by-item list, so there is no '
          'packing checklist.';
    } else if (order.status == OrderStatus.newOrder) {
      hint = 'Start preparing to tick items off.';
    } else if (order.status == OrderStatus.preparing) {
      hint = 'Tick each item as you pack it.';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ShopDecor.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist, size: 18, color: ShopColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasList ? 'Order Packing Checklist' : 'Order Items',
                  style: ShopText.subtitle,
                ),
              ),
              if (hasList)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ShopColors.surfaceMid,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${allDone ? order.itemCount : order.packedCount} / '
                    '${order.itemCount}',
                    style: ShopText.label,
                  ),
                ),
            ],
          ),
          if (hint.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(hint, style: ShopText.body),
          ],
          const SizedBox(height: 8),
          for (var i = 0; i < order.items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _ChecklistRow(
                item: order.items[i],
                checked: allDone || order.packedIndexes.contains(i),
                onChanged: canTick ? (packed) => onToggle(i, packed) : null,
              ),
            ),
          if (!hasList)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                order.itemsSummary ?? 'This order has no items listed.',
                style: ShopText.subtitle,
              ),
            ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: ShopDecor.tile(),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Payment Method', style: ShopText.body),
                    ),
                    Icon(
                      order.isPaidOnline
                          ? Icons.credit_card
                          : Icons.payments_outlined,
                      size: 14,
                      color: order.isPaidOnline
                          ? ShopColors.primary
                          : ShopColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      order.paymentMethod,
                      style: ShopText.bodyStrong.copyWith(
                        color: order.isPaidOnline
                            ? ShopColors.primary
                            : ShopColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Says plainly whether money still has to be collected.
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    order.isPaidOnline
                        ? 'Already paid. Do not collect payment at pickup.'
                        : 'Collect ${formatRs(order.total)} at pickup.',
                    style: ShopText.label,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text('Order Total', style: ShopText.subtitle),
                    ),
                    Text(
                      formatRs(order.total),
                      style: ShopText.title.copyWith(color: ShopColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.item,
    required this.checked,
    required this.onChanged,
  });

  final OrderItem item;
  final bool checked;

  /// Null makes the row read-only.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final toggle = onChanged;

    return Material(
      color: ShopColors.background,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: toggle == null ? null : () => toggle(!checked),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
          child: Row(
            children: [
              Checkbox(
                value: checked,
                activeColor: ShopColors.primary,
                onChanged:
                    toggle == null ? null : (value) => toggle(value ?? false),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.name} (${item.quantityLabel})',
                      style: ShopText.subtitle,
                    ),
                    Text(
                      '${item.quantityLabel} at ${formatRs(item.unitPrice)} '
                      'each',
                      style: ShopText.label,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(formatRs(item.lineTotal), style: ShopText.bodyStrong),
            ],
          ),
        ),
      ),
    );
  }
}
