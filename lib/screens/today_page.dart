import 'package:flutter/material.dart';

import '../widgets/dashboard_card.dart';
import 'tasks/tasks_page.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,

      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          24,
          20,
          24,
        ),

        children: [
          Text(
            'Oggi',
            style: Theme.of(context)
                .textTheme
                .displaySmall
                ?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
          ),

          const SizedBox(height: 6),

          Text(
            'La tua giornata in un colpo d’occhio',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                ),
          ),

          const SizedBox(height: 28),

          DashboardCard(
            icon: Icons.task_alt,
            title: 'Attività',
            value: 'Gestisci le tue attività',

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const TasksPage(),
                ),
              );
            },
          ),

          const SizedBox(height: 14),

          const DashboardCard(
            icon: Icons.repeat,
            title: 'Abitudini',
            value: '0 completate oggi',
          ),

          const SizedBox(height: 14),

          const DashboardCard(
            icon:
                Icons.shopping_cart_outlined,
            title: 'Lista della spesa',
            value: '0 prodotti',
          ),

          const SizedBox(height: 14),

          const DashboardCard(
            icon: Icons
                .account_balance_wallet_outlined,
            title: 'Spese del mese',
            value: '€ 0,00',
          ),
        ],
      ),
    );
  }
}