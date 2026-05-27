import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// Returns the safe-area bottom inset still needed in the current scaffold
// context. Uses MediaQuery.padding.bottom (which parent Scaffolds reduce as
// they consume insets) rather than viewPadding.bottom (which never changes).
// This avoids double-counting when this widget lives inside a nested Scaffold
// (e.g. a home-tab body already positioned above a BottomNavigationBar).
double effectiveBottomInset(BuildContext context, {double minimum = 0}) {
  final mediaQuery = MediaQuery.of(context);
  // In nested scaffold trees, padding.bottom can become 0 after parent
  // insets are consumed. Fall back to viewPadding.bottom to still respect
  // Android navigation button area and avoid clipped bottom content.
  final inset =
      math.max(mediaQuery.padding.bottom, mediaQuery.viewPadding.bottom);
  return math.max(inset, minimum);
}

double contentBottomPadding(BuildContext context, {bool hasFab = true}) {
  // Keep a safer global bottom gap so list/footer content never sits under
  // floating controls or navigation chrome across modules/devices.
  // hasFab: true  => inset + 128
  // hasFab: false => inset + 40
  return effectiveBottomInset(context) + (hasFab ? 128 : 40);
}

class AdaptiveBottomFab extends StatelessWidget {
  final Widget child;
  final double spacing;

  const AdaptiveBottomFab({
    super.key,
    required this.child,
    this.spacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Scaffold already accounts for bottom safe-area and default FAB margin.
    // Only apply optional extra spacing requested by the caller.
    return Padding(
      padding: EdgeInsets.only(
        bottom: spacing,
      ),
      child: child,
    );
  }
}

class TwoStateSegmentedTab extends StatelessWidget {
  final bool secondSelected;
  final String firstLabel;
  final String secondLabel;
  final IconData firstIcon;
  final IconData secondIcon;
  final ValueChanged<bool> onChanged;
  final EdgeInsetsGeometry? padding;
  final bool enableSwipe;
  final double swipeVelocityThreshold;

  const TwoStateSegmentedTab({
    super.key,
    required this.secondSelected,
    required this.firstLabel,
    required this.secondLabel,
    required this.firstIcon,
    required this.secondIcon,
    required this.onChanged,
    this.padding,
    this.enableSwipe = true,
    this.swipeVelocityThreshold = 180,
  });

  ButtonStyle _tabStyle(BuildContext context) {
    return ButtonStyle(
      side: const WidgetStatePropertyAll(BorderSide(color: Colors.transparent)),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return Theme.of(context).colorScheme.onSurface;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTheme.primaryColor;
        }
        return Theme.of(context).colorScheme.surface;
      }),
    );
  }

  void _onSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < swipeVelocityThreshold) {
      return;
    }

    if (velocity < 0 && !secondSelected) {
      onChanged(true);
    } else if (velocity > 0 && secondSelected) {
      onChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tab = SegmentedButton<bool>(
      segments: [
        ButtonSegment<bool>(
          value: false,
          label: Text(firstLabel),
          icon: Icon(firstIcon, size: 16),
        ),
        ButtonSegment<bool>(
          value: true,
          label: Text(secondLabel),
          icon: Icon(secondIcon, size: 16),
        ),
      ],
      selected: {secondSelected},
      style: _tabStyle(context),
      onSelectionChanged: (selection) => onChanged(selection.first),
    );

    final content = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: tab,
    );

    if (!enableSwipe) {
      return content;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: _onSwipe,
      child: content,
    );
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final bool showBackButton;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.onBack,
    this.showBackButton = true,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedBackground = backgroundColor ?? theme.colorScheme.surface;
    final resolvedTextColor = textColor ?? theme.colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: resolvedBackground,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showBackButton)
                GestureDetector(
                  onTap: onBack ?? () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: resolvedTextColor,
                    ),
                  ),
                )
              else
                const SizedBox(width: 40),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: resolvedTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (actions != null && actions!.isNotEmpty)
                Row(children: actions!)
              else
                const SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class GradientCard extends StatelessWidget {
  final Widget child;
  final Color startColor;
  final Color endColor;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final BorderRadius borderRadius;

  const GradientCard({
    super.key,
    required this.child,
    this.startColor = AppTheme.primaryColor,
    this.endColor = AppTheme.secondaryColor,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [startColor, endColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: startColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class ProgressIndicatorWidget extends StatelessWidget {
  final double value;
  final String label;
  final String percentage;
  final Color progressColor;

  const ProgressIndicatorWidget({
    super.key,
    required this.value,
    required this.label,
    required this.percentage,
    this.progressColor = AppTheme.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textColor,
              ),
            ),
            Text(
              percentage,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 8,
            backgroundColor: AppTheme.dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
      ],
    );
  }
}

class AnimatedStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const AnimatedStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppTheme.primaryColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoadingWidget extends StatelessWidget {
  final String? message;

  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
