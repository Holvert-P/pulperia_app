import 'package:app/src/features/debts/data/repositories/receivable_repository_impl.dart';
import 'package:app/src/features/debts/domain/usecases/receivable_usecases.dart';
import 'package:app/src/features/debts/presentation/controllers/debt_list_controller.dart';
import 'package:app/src/features/debts/presentation/pages/add_payment_page.dart';
import 'package:app/src/features/debts/presentation/pages/debt_detail_page.dart';
import 'package:app/src/features/debts/presentation/pages/debt_form_page.dart';
import 'package:app/src/features/debts/presentation/widgets/receivable_filter_bottom_sheet.dart';
import 'package:app/src/features/debts/presentation/widgets/receivable_list_item.dart';
import 'package:app/src/features/debts/presentation/widgets/receivable_quick_filters.dart';
import 'package:app/src/features/debts/presentation/widgets/receivable_search_bar.dart';
import 'package:app/src/features/debts/presentation/widgets/receivable_sort_sheet.dart';
import 'package:app/src/features/debts/presentation/widgets/receivable_summary_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccountsReceivablePage extends StatelessWidget {
  const AccountsReceivablePage({super.key});

  Future<void> _openCreate(BuildContext context) async {
    final created = await Navigator.of(
      context,
    ).pushNamed<bool>(DebtFormPage.routeName);
    if (created == true && context.mounted) {
      await context.read<DebtListController>().load();
    }
  }

  Future<void> _openDetail(BuildContext context, String receivableId) async {
    final changed = await Navigator.of(context).pushNamed<bool>(
      DebtDetailPage.routeName,
      arguments: DebtDetailArgs(debtId: receivableId),
    );
    if (changed == true && context.mounted) {
      await context.read<DebtListController>().load();
    }
  }

  Future<void> _openRegisterPayment(
    BuildContext context, {
    required String receivableId,
    required double maxPrincipal,
    required double maxInterest,
    required bool canRegisterPayment,
  }) async {
    if (!canRegisterPayment) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta saldada: no admite pagos')),
      );
      return;
    }
    final ok = await Navigator.of(context).pushNamed<bool>(
      AddPaymentPage.routeName,
      arguments: AddPaymentArgs(
        receivableId: receivableId,
        maxPrincipalAmount: maxPrincipal,
        maxInterestAmount: maxInterest,
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<DebtListController>().load();
    }
  }

  Future<void> _openFilters(BuildContext context) async {
    final c = context.read<DebtListController>();
    final next = await showReceivableFilterBottomSheet(
      context,
      initial: c.advancedFilter,
    );
    if (next == null) return;
    c.setAdvancedFilter(next);
  }

  Future<void> _openSort(BuildContext context) async {
    final c = context.read<DebtListController>();
    final next = await showReceivableSortSheet(context, initial: c.sortOption);
    if (next == null) return;
    c.setSortOption(next);
  }

  @override
  Widget build(BuildContext context) {
    final repo = ReceivableRepositoryImpl();
    return ChangeNotifierProvider(
      create: (_) => DebtListController(
        getReceivables: GetReceivables(repo),
        getPortfolioSummary: GetPortfolioSummary(repo),
      )..load(),
      child: Builder(
        builder: (context) {
          final c = context.watch<DebtListController>();
          return Scaffold(
            appBar: AppBar(
              title: const Text('Cuentas por cobrar'),
              actions: [
                IconButton(
                  onPressed: c.loading ? null : () => _openFilters(context),
                  tooltip: 'Filtros',
                  icon: const Icon(Icons.tune_outlined),
                ),
                IconButton(
                  onPressed: c.loading ? null : () => _openSort(context),
                  tooltip: 'Ordenar',
                  icon: const Icon(Icons.sort_outlined),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: 'debts_fab',
              onPressed: () => _openCreate(context),
              child: const Icon(Icons.add),
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: RefreshIndicator(
                      onRefresh: c.load,
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: ReceivableSummarySection(summary: c.summary),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 12)),
                          SliverToBoxAdapter(
                            child: ReceivableSearchBar(
                              controller: c.searchController,
                              onChanged: c.setSearchQuery,
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 10)),
                          SliverToBoxAdapter(
                            child: ReceivableQuickFilters(
                              selected: c.quickFilter,
                              counts: c.quickFilterCounts,
                              onSelected: c.setQuickFilter,
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 12)),
                          if (c.loading)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (c.error != null)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _ErrorState(
                                message: c.error!,
                                onRetry: c.load,
                              ),
                            )
                          else if (c.items.isEmpty)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: _EmptyState(),
                            )
                          else
                            SliverList.separated(
                              itemCount: c.items.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = c.items[index];
                                return ReceivableListItem(
                                  item: item,
                                  onTap: () => _openDetail(
                                    context,
                                    item.receivable.receivableId,
                                  ),
                                  onQuickPay: item.canRegisterPayment
                                      ? () => _openRegisterPayment(
                                          context,
                                          receivableId:
                                              item.receivable.receivableId,
                                          maxPrincipal:
                                              item.balances.principalPending,
                                          maxInterest:
                                              item.balances.interestPending,
                                          canRegisterPayment:
                                              item.canRegisterPayment,
                                        )
                                      : null,
                                );
                              },
                            ),
                          const SliverToBoxAdapter(child: SizedBox(height: 84)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.credit_score_outlined,
                  size: 56,
                  color: scheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Sin cuentas por cobrar',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Registra ventas al crédito para llevar trazabilidad real de cobros, intereses y gestión.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 52, color: scheme.error),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
