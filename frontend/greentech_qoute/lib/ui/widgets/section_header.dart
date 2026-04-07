import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Section header with icon and title
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;
  final EdgeInsets padding;
  final bool showDivider;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.sm),
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: padding,
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.headlineSmall,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        if (showDivider) const Divider(),
      ],
    );
  }
}

/// Card container with section styling
class SectionCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final IconData? icon;
  final EdgeInsets padding;
  final Color? backgroundColor;

  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              SectionHeader(
                title: title!,
                icon: icon,
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
              ),
            child,
          ],
        ),
      ),
    );
  }
}

/// Info row for displaying label-value pairs
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppTheme.secondaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: isBold
                  ? AppTypography.titleMedium.copyWith(color: valueColor)
                  : AppTypography.bodyMedium.copyWith(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status badge widget
class StatusBadge extends StatelessWidget {
  final String status;
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  Color get _backgroundColor {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppTheme.approvedColor.withOpacity(0.15);
      case 'rejected':
        return AppTheme.rejectedColor.withOpacity(0.15);
      case 'expired':
        return AppTheme.expiredColor.withOpacity(0.15);
      case 'pending':
      default:
        return AppTheme.pendingColor.withOpacity(0.15);
    }
  }

  Color get _textColor {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppTheme.approvedColor;
      case 'rejected':
        return AppTheme.rejectedColor;
      case 'expired':
        return AppTheme.expiredColor;
      case 'pending':
      default:
        return AppTheme.pendingColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(isCompact ? 4 : 6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: isCompact ? 11 : 13,
          fontWeight: FontWeight.w600,
          color: _textColor,
        ),
      ),
    );
  }
}

/// Empty state widget
class EmptyState extends StatelessWidget {
  final String message;
  final String? subMessage;
  final IconData icon;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.message,
    this.subMessage,
    this.icon = Icons.folder_open,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppTheme.hintText,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.headlineSmall.copyWith(
                color: AppTheme.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            if (subMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subMessage!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppTheme.hintText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
