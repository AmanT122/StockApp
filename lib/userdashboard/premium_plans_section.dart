// File path: lib/userdashboard/premium_plans_section.dart

import 'package:flutter/material.dart';
import 'payment_helpers.dart';

class PremiumPlansSection extends StatelessWidget {
  const PremiumPlansSection({super.key});
  @override
  Widget build(BuildContext context) {
    final double maxWidth = MediaQuery.of(context).size.width > 900
        ? 900
        : double.infinity;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Premium Plans",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1f4037),
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  return Flex(
                    direction: isWide ? Axis.horizontal : Axis.vertical,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _PlanCard(
                        icon: Icons.star_border,
                        title: "Basic Plan",
                        subtitle: "Premium plan for Free",
                        description:
                            "Get proper stock market tips and analysis",
                        price: "Free",
                        buttonColor: Colors.greenAccent.shade700,
                        onPressed: () async {
                          await handleFreePlanJoin(context);
                        },
                      ),
                      if (isWide)
                        const SizedBox(width: 18)
                      else
                        const SizedBox(height: 18),
                      _PlanCard(
                        icon: Icons.trending_up,
                        title: "Standard Plan",
                        subtitle: "Premium plan for one month",
                        description: "Get accurate stock market insights",
                        price: "₹1 / month",
                        buttonColor: Colors.blueAccent,
                        onPressed: () {
                          launchUPI(
                            context,
                            payeeVPA: 'jaydarji1977@oksbi',
                            payeeName: 'StockTrade',
                            amount: '1', // Changed to 1
                            transactionNote: 'Standard Plan Payment',
                            planType: 'Standard Plan',
                          );
                        },
                      ),
                      if (isWide)
                        const SizedBox(width: 18)
                      else
                        const SizedBox(height: 18),
                      _PlanCard(
                        icon: Icons.workspace_premium,
                        title: "Premium Plan",
                        subtitle: "Premium plan for three months",
                        description: "Advanced stock trading analysis",
                        price: "₹1 / 3 months",
                        buttonColor: Colors.deepPurple,
                        onPressed: () {
                          launchUPI(
                            context,
                            payeeVPA: 'jaydarji1977@oksbi.com',
                            payeeName: 'StockTrade',
                            amount: '1', // Changed to 1
                            transactionNote: 'Premium Plan Payment',
                            planType: 'Premium Plan',
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final String price;
  final Color buttonColor;
  final VoidCallback onPressed;

  const _PlanCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.price,
    required this.buttonColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 400),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: buttonColor.withOpacity(0.12),
                child: Icon(icon, size: 32, color: buttonColor),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: buttonColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                price,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: buttonColor,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: onPressed,
                  child: const Text(
                    "Get Started",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

