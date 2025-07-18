import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class ModelIndicator extends StatelessWidget {
  final bool showIcon;
  final double fontSize;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const ModelIndicator({
    super.key,
    this.showIcon = true,
    this.fontSize = 11,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final modelInfo = appProvider.currentModelInfo;
        if (modelInfo == null || !appProvider.isModelReady) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: margin ?? const EdgeInsets.only(top: 4),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcon) ...[
                Icon(
                  Icons.smart_toy_outlined,
                  size: fontSize + 1,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                modelInfo.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: fontSize,
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}