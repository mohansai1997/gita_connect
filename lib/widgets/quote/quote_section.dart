import 'package:flutter/material.dart';

class QuoteSection extends StatelessWidget {
  const QuoteSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quote icon and title
          Row(
            children: [
              Icon(
                Icons.format_quote,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Daily Wisdom',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Quote text
          Text(
            '"If one reads Bhagavad-gītā regularly and attentively, he can surpass all studies of Vedic literature"',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              height: 1.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          
          // Author attribution
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '— A. C. Bhaktivedanta Swami Prabhupada',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}