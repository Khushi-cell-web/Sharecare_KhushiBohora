import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../widgets/empty_error_state.dart';

/// Full-screen empty or error state when navigation leads to no content.
/// Pass [isError] and [message] via ModalRoute.of(context)?.settings.arguments.
class EmptyStateScreen extends StatelessWidget {
  const EmptyStateScreen({
    super.key,
    this.title = 'Nothing here',
    this.subtitle,
    this.isError = false,
    this.showBackButton = true,
  });

  final String title;
  final String? subtitle;
  final bool isError;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final isErr = args?['isError'] as bool? ?? isError;
    final msg = args?['message'] as String? ?? title;
    final sub = args?['subtitle'] as String? ?? subtitle;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: showBackButton
          ? AppBar(
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
              title: Text(isErr ? 'Error' : 'No results'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.maybePop(context),
              ),
            )
          : null,
      body: isErr
          ? ErrorStateWidget(
              message: msg,
              onRetry: () => Navigator.maybePop(context),
            )
          : EmptyStateWidget(
              title: msg,
              subtitle: sub,
              icon: Icons.inbox_rounded,
            ),
    );
  }
}
