import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/auto_card.dart';
import '../widgets/auto_top_bar.dart';
import '../widgets/section_header.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const AutoTopBar(
        title: 'Subscription',
        subtitle: 'Compare plans and unlock the full AutoSched AI experience',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 40),
        children: [
          // ── Pro Hero Banner ────────────────────────────────────────────
          AutoCard(
            padding: EdgeInsets.zero,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F1D96), Color(0xFF7C3AED), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium_rounded,
                                size: 14, color: Colors.white),
                            SizedBox(width: 5),
                            Text(
                              'PRO',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24).withOpacity(0.20),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Most Popular',
                          style: TextStyle(
                            color: Color(0xFFFBBF24),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'AutoSched AI Pro',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Everything you need to study smarter, not harder.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '₱90',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 40,
                          height: 1,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 5, left: 4),
                        child: Text(
                          '/ month',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.purple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              '🚀 Subscriptions coming soon! Stay tuned.',
                            ),
                            backgroundColor: AppTheme.purple,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      child: const Text('Subscribe Now — ₱90 / month'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Plan Comparison ────────────────────────────────────────────
          const SectionHeader(
            title: 'Plan Comparison',
            subtitle: "See what's included in each tier.",
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Free Card
              Expanded(
                child: AutoCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.onSurface.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.lock_open_rounded,
                              size: 16,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Free',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '₱0',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'forever',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                      const Divider(height: 24),
                      ..._freeFeatures.map(
                        (f) => _FeatureRow(
                          label: f.label,
                          included: f.included,
                          detail: f.detail,
                          isPro: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Pro Card
              Expanded(
                child: AutoCard(
                  padding: EdgeInsets.zero,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF2D1B69), const Color(0xFF1E1B4B)]
                            : [const Color(0xFFF5F3FF), const Color(0xFFEDE9FE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.purple.withOpacity(0.35),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.purple.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.workspace_premium_rounded,
                                size: 16,
                                color: AppTheme.purple,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Pro',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppTheme.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '₱90',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppTheme.purple,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'per month',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        Divider(
                          height: 24,
                          color: AppTheme.purple.withOpacity(0.25),
                        ),
                        ..._proFeatures.map(
                          (f) => _FeatureRow(
                            label: f.label,
                            included: f.included,
                            detail: f.detail,
                            isPro: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Pro Benefits ───────────────────────────────────────────────
          const SectionHeader(
            title: 'What You Get with Pro',
            subtitle: 'Unlock the full AutoSched AI experience.',
          ),
          ..._proBenefits.map(
            (b) => AutoCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: b.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(b.icon, color: b.color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          b.description,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom CTA ─────────────────────────────────────────────────
          const SizedBox(height: 8),
          AutoCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppTheme.purple,
                  size: 36,
                ),
                const SizedBox(height: 10),
                Text(
                  'Ready to study smarter?',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Upgrade to AutoSched AI Pro for only ₱90/month and take full control of your academic schedule.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.purple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            '🚀 Subscriptions coming soon! Stay tuned.',
                          ),
                          backgroundColor: AppTheme.purple,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.workspace_premium_rounded),
                    label: const Text(
                      'Get Pro — ₱90 / month',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
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

// ── Data ─────────────────────────────────────────────────────────────────────

class _Feature {
  const _Feature({required this.label, required this.included, this.detail});
  final String label;
  final bool included;
  final String? detail;
}

const _freeFeatures = [
  _Feature(label: 'Task management', included: true, detail: 'Up to 5 tasks'),
  _Feature(label: 'Manual class entry', included: true),
  _Feature(label: 'Basic planner view', included: true, detail: '3-day view'),
  _Feature(label: 'Local storage', included: true),
  _Feature(label: 'Smart auto-scheduling', included: false),
  _Feature(label: 'AI Assistant', included: false),
  _Feature(label: 'COR Scanner', included: false),
  _Feature(label: 'Cloud sync & backup', included: false),
];

const _proFeatures = [
  _Feature(label: 'Task management', included: true, detail: 'Unlimited'),
  _Feature(label: 'Manual class entry', included: true),
  _Feature(label: 'Full planner view', included: true, detail: 'Unlimited'),
  _Feature(label: 'Cloud storage', included: true),
  _Feature(label: 'Smart auto-scheduling', included: true),
  _Feature(label: 'AI Assistant', included: true, detail: 'Unlimited'),
  _Feature(label: 'COR Scanner', included: true, detail: 'OCR + AI'),
  _Feature(label: 'Cloud sync & backup', included: true),
];

class _Benefit {
  const _Benefit({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String description;
}

const _proBenefits = [
  _Benefit(
    icon: Icons.auto_awesome_rounded,
    color: AppTheme.purple,
    title: 'Smart Auto-Scheduling',
    description:
        'The AutoSched engine analyzes your classes, tasks, and preferences to automatically generate optimized study blocks that fit your day — no manual planning needed.',
  ),
  _Benefit(
    icon: Icons.smart_toy_rounded,
    color: AppTheme.primary,
    title: 'AI Study Assistant',
    description:
        'Chat with an AI assistant powered by Groq LLM. Get help deciding what to study first, understanding your schedule, checking deadlines, and navigating a new term.',
  ),
  _Benefit(
    icon: Icons.document_scanner_rounded,
    color: AppTheme.cyan,
    title: 'COR Scanner',
    description:
        'Scan your Certificate of Registration using your camera or gallery. OCR and AI automatically extract your full class schedule and import it into the planner — no typing required.',
  ),
  _Benefit(
    icon: Icons.cloud_sync_rounded,
    color: AppTheme.success,
    title: 'Cloud Sync & Backup',
    description:
        'Your subjects, tasks, class schedules, and study blocks are securely backed up to the cloud via Firebase. Restore everything instantly after switching devices or reinstalling.',
  ),
  _Benefit(
    icon: Icons.leaderboard_rounded,
    color: AppTheme.warning,
    title: 'Priority Task Ranking',
    description:
        'Pro unlocks the full priority algorithm that ranks your tasks by deadline, difficulty, importance, workload, and missed-deadline penalty — so you always know what to tackle next.',
  ),
  _Benefit(
    icon: Icons.all_inclusive_rounded,
    color: AppTheme.danger,
    title: 'Unlimited Tasks & Subjects',
    description:
        'Add as many tasks and subjects as you need for the whole semester. No caps, no restrictions — the app scales with your workload.',
  ),
];

// ── Feature Row Widget ────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.label,
    required this.included,
    required this.isPro,
    this.detail,
  });

  final String label;
  final bool included;
  final bool isPro;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final checkColor = isPro ? AppTheme.purple : AppTheme.success;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            included ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 16,
            color: included ? checkColor : colors.onSurface.withOpacity(0.25),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: included
                        ? colors.onSurface
                        : colors.onSurface.withOpacity(0.35),
                  ),
                ),
                if (detail != null)
                  Text(
                    detail!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: included
                          ? (isPro ? AppTheme.purple : AppTheme.success)
                          : colors.onSurface.withOpacity(0.25),
                      fontWeight: FontWeight.w700,
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
