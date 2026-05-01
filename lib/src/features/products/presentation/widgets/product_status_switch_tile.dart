import 'package:flutter/material.dart';

class ProductStatusSwitchTile extends StatelessWidget {
  const ProductStatusSwitchTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      contentPadding: EdgeInsets.zero,
    );
  }
}
