import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/accounts/presentation/pages/accounts_page.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
import '../../features/transactions/presentation/pages/add_transaction_page.dart';
import '../../features/budgets/presentation/pages/budgets_page.dart';
import '../../features/goals/presentation/pages/goals_page.dart';
import '../../features/fixed_bills/presentation/pages/fixed_bills_page.dart';
import '../../features/expense_diary/presentation/pages/expense_diary_page.dart';
import '../../features/income_sources/presentation/pages/income_sources_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/debts/presentation/pages/debts_page.dart';
import '../../features/external_debts/presentation/pages/external_debts_page.dart';
import '../../features/analysis/presentation/pages/analysis_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/cards/presentation/pages/cards_page.dart';
import '../../shared/widgets/main_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.whenOrNull(
        data: (s) => s.session != null,
      ) ?? false;

      final isAuthRoute = state.matchedLocation == '/' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/';
      if (isLoggedIn && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),

      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),
          GoRoute(path: '/transactions', builder: (_, __) => const TransactionsPage()),
          GoRoute(path: '/accounts', builder: (_, __) => const AccountsPage()),
          GoRoute(path: '/reports', builder: (_, __) => const ReportsPage()),
          GoRoute(
            path: '/transactions/add',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return AddTransactionPage(initialType: extra?['type']);
            },
          ),
          GoRoute(path: '/budgets', builder: (_, __) => const BudgetsPage()),
          GoRoute(path: '/goals', builder: (_, __) => const GoalsPage()),
          GoRoute(path: '/fixed-bills', builder: (_, __) => const FixedBillsPage()),
          GoRoute(path: '/diary', builder: (_, __) => const ExpenseDiaryPage()),
          GoRoute(path: '/income-sources', builder: (_, __) => const IncomeSourcesPage()),
          GoRoute(path: '/notifications', builder: (_, __) => const NotificationsPage()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
          GoRoute(path: '/cards', builder: (_, __) => const CardsPage()),
          GoRoute(path: '/debts', builder: (_, __) => const DebtsPage()),
          GoRoute(path: '/external-debts', builder: (_, __) => const ExternalDebtsPage()),
          GoRoute(path: '/analysis', builder: (_, __) => const AnalysisPage()),
        ],
      ),
    ],
  );
});
