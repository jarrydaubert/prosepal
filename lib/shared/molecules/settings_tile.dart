import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// iOS-style settings tile with leading icon, title, subtitle, and trailing
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(title, style: TextStyle(color: titleColor)),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing:
          trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right, color: AppColors.textHint)
              : null),
      onTap: onTap,
    );
  }
}

/// Settings tile with a switch toggle
class SettingsToggleTile extends StatelessWidget {
  const SettingsToggleTile({
    super.key,
    required this.leading,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: Switch.adaptive(value: value, onChanged: onChanged),
    );
  }
}

/// Destructive settings tile (red text for dangerous actions)
class SettingsDestructiveTile extends StatelessWidget {
  const SettingsDestructiveTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      leading: Icon(icon, color: AppColors.error),
      title: title,
      subtitle: subtitle,
      titleColor: AppColors.error,
      onTap: onTap,
    );
  }
}
