import 'package:app/src/features/debts/domain/entities/portfolio_summary.dart';
import 'package:app/src/features/debts/domain/entities/receivable_detail.dart';
import 'package:app/src/features/debts/domain/usecases/receivable_usecases.dart';
import 'package:flutter/material.dart';

class DebtListController extends ChangeNotifier {
  DebtListController({
    required GetReceivables getReceivables,
    required GetPortfolioSummary getPortfolioSummary,
  }) : _getReceivables = getReceivables,
       _getPortfolioSummary = getPortfolioSummary;

  final GetReceivables _getReceivables;
  final GetPortfolioSummary _getPortfolioSummary;

  bool _loading = false;
  String? _error;
  List<ReceivableDetail> _allItems = const [];
  PortfolioSummary? _summary;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  ReceivableQuickFilter _quickFilter = ReceivableQuickFilter.all;
  ReceivableSortOption _sortOption = ReceivableSortOption.mostOverdue;
  ReceivableAdvancedFilter _advancedFilter = const ReceivableAdvancedFilter();

  bool get loading => _loading;
  String? get error => _error;
  PortfolioSummary? get summary => _summary;
  TextEditingController get searchController => _searchController;
  ReceivableQuickFilter get quickFilter => _quickFilter;
  ReceivableSortOption get sortOption => _sortOption;
  ReceivableAdvancedFilter get advancedFilter => _advancedFilter;

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setQuickFilter(ReceivableQuickFilter value) {
    _quickFilter = value;
    notifyListeners();
  }

  void setSortOption(ReceivableSortOption value) {
    _sortOption = value;
    notifyListeners();
  }

  void setAdvancedFilter(ReceivableAdvancedFilter value) {
    _advancedFilter = value;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _getReceivables(),
        _getPortfolioSummary(),
      ]);
      _allItems = results.first as List<ReceivableDetail>;
      _summary = results.last as PortfolioSummary;
    } catch (e) {
      _error = 'No se pudieron cargar las cuentas por cobrar';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  List<ReceivableDetail> get items {
    final base = _applySearchAndAdvanced(_allItems);
    final filtered = _applyQuickFilter(base, _quickFilter);
    final sorted = [...filtered]..sort(_compareForSort(_sortOption));
    return sorted;
  }

  Map<ReceivableQuickFilter, int> get quickFilterCounts {
    final base = _applySearchAndAdvanced(_allItems);
    return {
      for (final f in ReceivableQuickFilter.values)
        f: _applyQuickFilter(base, f).length,
    };
  }

  List<ReceivableDetail> _applySearchAndAdvanced(List<ReceivableDetail> input) {
    final q = _normalize(_searchQuery);
    var list = input;
    if (q.isNotEmpty) {
      list = list.where((d) {
        final name = _normalize(d.receivable.customerName);
        final ref = _normalize(d.receivable.receivableId);
        return name.contains(q) || ref.contains(q);
      }).toList();
    }

    final f = _advancedFilter;
    if (f.statuses.isNotEmpty) {
      list = list
          .where((d) => f.statuses.contains(d.receivable.status))
          .toList();
    }
    if (f.minBalance != null) {
      list = list
          .where((d) => d.balances.totalPending >= f.minBalance! - 0.005)
          .toList();
    }
    if (f.maxBalance != null) {
      list = list
          .where((d) => d.balances.totalPending <= f.maxBalance! + 0.005)
          .toList();
    }
    if (f.dueFrom != null) {
      list = list
          .where((d) => !d.receivable.dueDate.isBefore(f.dueFrom!))
          .toList();
    }
    if (f.dueTo != null) {
      list = list
          .where((d) => !d.receivable.dueDate.isAfter(f.dueTo!))
          .toList();
    }
    if (f.withInterestPending != null) {
      if (f.withInterestPending == true) {
        list = list.where((d) => d.balances.interestPending > 0.005).toList();
      } else {
        list = list.where((d) => d.balances.interestPending <= 0.005).toList();
      }
    }
    if (f.noRecentPaymentOnly) {
      list = list.where(_isNoRecentPayment).toList();
    }

    return list;
  }

  List<ReceivableDetail> _applyQuickFilter(
    List<ReceivableDetail> input,
    ReceivableQuickFilter filter,
  ) {
    return switch (filter) {
      ReceivableQuickFilter.all => input,
      ReceivableQuickFilter.active =>
        input.where((d) => d.receivable.status == 'active').toList(),
      ReceivableQuickFilter.overdue =>
        input.where((d) => d.receivable.status == 'overdue').toList(),
      ReceivableQuickFilter.paid =>
        input.where((d) => d.receivable.status == 'paid').toList(),
      ReceivableQuickFilter.withInterest =>
        input.where((d) => d.balances.interestPending > 0.005).toList(),
      ReceivableQuickFilter.noRecentPayment =>
        input.where(_isNoRecentPayment).toList(),
    };
  }

  bool _isNoRecentPayment(ReceivableDetail d) {
    final last = d.balances.lastPaymentAt;
    if (last == null) return true;
    return DateTime.now().difference(last).inDays >= 14;
  }

  int Function(ReceivableDetail, ReceivableDetail) _compareForSort(
    ReceivableSortOption option,
  ) {
    return (a, b) {
      switch (option) {
        case ReceivableSortOption.highestBalance:
          return b.balances.totalPending.compareTo(a.balances.totalPending);
        case ReceivableSortOption.mostOverdue:
          return b.balances.daysOverdue.compareTo(a.balances.daysOverdue);
        case ReceivableSortOption.lastPayment:
          final ax = a.balances.lastPaymentAt;
          final bx = b.balances.lastPaymentAt;
          if (ax == null && bx == null) return 0;
          if (ax == null) return 1;
          if (bx == null) return -1;
          return bx.compareTo(ax);
        case ReceivableSortOption.customerName:
          return a.receivable.customerName.toLowerCase().compareTo(
            b.receivable.customerName.toLowerCase(),
          );
        case ReceivableSortOption.mostRecent:
          return b.receivable.createdAt.compareTo(a.receivable.createdAt);
      }
    };
  }

  String _normalize(String value) {
    final lower = value.toLowerCase().trim();
    final withoutDiacritics = lower
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ñ', 'n');
    return withoutDiacritics.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

enum ReceivableQuickFilter {
  all,
  active,
  overdue,
  paid,
  withInterest,
  noRecentPayment,
}

enum ReceivableSortOption {
  highestBalance,
  mostOverdue,
  lastPayment,
  customerName,
  mostRecent,
}

class ReceivableAdvancedFilter {
  const ReceivableAdvancedFilter({
    this.statuses = const {},
    this.minBalance,
    this.maxBalance,
    this.dueFrom,
    this.dueTo,
    this.withInterestPending,
    this.noRecentPaymentOnly = false,
  });

  final Set<String> statuses;
  final double? minBalance;
  final double? maxBalance;
  final DateTime? dueFrom;
  final DateTime? dueTo;
  final bool? withInterestPending;
  final bool noRecentPaymentOnly;
}
