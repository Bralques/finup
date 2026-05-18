import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/transactions')) return 1;
    if (loc.startsWith('/accounts')) return 2;
    if (loc.startsWith('/reports')) return 3;
    if (['/budgets', '/goals', '/fixed-bills', '/diary',
         '/income-sources', '/notifications', '/debts',
         '/external-debts', '/profile'].any(loc.startsWith)) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _selectedIndex(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF141414),
          border: Border(top: BorderSide(color: Color(0xFF222222), width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: idx,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          onDestinationSelected: (i) {
            switch (i) {
              case 0: context.go('/dashboard');
              case 1: context.go('/transactions');
              case 2: context.go('/accounts');
              case 3: context.go('/reports');
              case 4: _showMore(context);
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Início',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Transações',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_outlined),
              selectedIcon: Icon(Icons.account_balance_rounded),
              label: 'Contas',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Relatórios',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Mais',
            ),
          ],
        ),
      ),
    );
  }

  void _showMore(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _GridItem(icon: Icons.track_changes_rounded, label: 'Metas',
                      onTap: () { Navigator.pop(ctx); context.go('/goals'); }),
                  _GridItem(icon: Icons.pie_chart_outline_rounded, label: 'Orçamentos',
                      onTap: () { Navigator.pop(ctx); context.go('/budgets'); }),
                  _GridItem(icon: Icons.repeat_rounded, label: 'Fixas',
                      onTap: () { Navigator.pop(ctx); context.go('/fixed-bills'); }),
                  _GridItem(icon: Icons.book_outlined, label: 'Diário',
                      onTap: () { Navigator.pop(ctx); context.go('/diary'); }),
                  _GridItem(icon: Icons.auto_awesome_rounded, label: 'Análise IA',
                      onTap: () { Navigator.pop(ctx); context.go('/analysis'); }),
                  _GridItem(icon: Icons.payments_outlined, label: 'Rendas',
                      onTap: () { Navigator.pop(ctx); context.go('/income-sources'); }),
                  _GridItem(icon: Icons.people_alt_outlined, label: 'Cobranças',
                      onTap: () { Navigator.pop(ctx); context.go('/debts'); }),
                  _GridItem(icon: Icons.account_balance_outlined, label: 'Serasa',
                      onTap: () { Navigator.pop(ctx); context.go('/external-debts'); }),
                  _GridItem(icon: Icons.notifications_outlined, label: 'Avisos',
                      onTap: () { Navigator.pop(ctx); context.go('/notifications'); }),
                  _GridItem(icon: Icons.manage_accounts_rounded, label: 'Conta',
                      onTap: () { Navigator.pop(ctx); context.go('/profile'); }),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _GridItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GridItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF272727)),
            ),
            child: Icon(icon, color: Colors.white70, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF888888),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
