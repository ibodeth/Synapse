import 'package:flutter/material.dart';
import 'dart:ui';
import '../../providers/news_provider.dart';
import 'package:provider/provider.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double? width;
  final double? height;

  const GlassContainer({
    Key? key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 24.0,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final newsProvider = Provider.of<NewsProvider>(context);
    final borderColor = newsProvider.themeMode == ThemeMode.dark 
        ? Colors.white.withOpacity(0.1) 
        : Colors.black.withOpacity(0.1);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: newsProvider.glassColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: newsProvider.themeMode == ThemeMode.light 
              ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 4))] 
              : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
