import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../../fixed_bills/presentation/providers/fixed_bills_provider.dart';
import '../../../budgets/presentation/providers/budgets_provider.dart';

// Dashboard aggregates data from multiple providers.
// Uses individual feature providers directly in DashboardPage.
// This file exposes convenience re-exports for the dashboard.

export '../../../accounts/presentation/providers/accounts_provider.dart'
    show accountsProvider, totalBalanceProvider;
export '../../../transactions/presentation/providers/transactions_provider.dart'
    show transactionsProvider, monthlySummaryProvider, selectedMonthProvider;
export '../../../fixed_bills/presentation/providers/fixed_bills_provider.dart'
    show upcomingBillsProvider;
export '../../../budgets/presentation/providers/budgets_provider.dart'
    show budgetsProvider;
