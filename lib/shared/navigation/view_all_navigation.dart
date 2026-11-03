import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sparrow/features/view_all/view_all_args.dart';

/// Centralized navigation helper to open the shared View All page
/// within the active branch of StatefulShellRoute.indexedStack.
void openViewAll(BuildContext context, ViewAllArgs args) {
  // Inspect current route location to stay in the active shell branch
  final location = GoRouterState.of(context).uri.toString();

  if (location.startsWith('/anime')) {
    context.push('/anime/view-all', extra: args);
  } else if (location.startsWith('/search')) {
    context.push('/search/view-all', extra: args);
  } else if (args.isTv) {
    context.push('/anime/view-all', extra: args);
  } else {
    context.push('/view-all', extra: args);
  }
}
