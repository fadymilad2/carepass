part of '../../pages/card_page.dart';

class _CardContent extends StatelessWidget {
  final HealthCard card;
  const _CardContent({required this.card});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Text('My Card', style: AppTextStyles.headlineLarge),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.no_photography_outlined,
                      size: 14,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text('Protected', style: AppTextStyles.labelSmall),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _DigitalCard(card: card),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _CardStatusSection(card: card),
          ),

          const SizedBox(height: 16),

          // ✅ NEW — Family Members / Upgrade prompt.
          // Only shown for active subscribers.
          if (card.isActive) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const _FamilyOrUpgradeSection(),
            ),
            const SizedBox(height: 16),
          ],

          if (card.isActive) ...[
            const HealthChecksSection(),
            const SizedBox(height: 16),
          ],

          if (!card.isActive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const _SubscribeCTA(),
            ),

          if (!card.isActive) const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const _QuickActionsSection(),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ✅ NEW — Family Members / Upgrade Section
//  Self-contained, reads directly from Firestore — no
//  BLoC changes needed. Shows a "Manage" link into the
//  members list for Family subscribers, or an "Upgrade"
//  prompt for Individual subscribers.
// ─────────────────────────────────────────────
