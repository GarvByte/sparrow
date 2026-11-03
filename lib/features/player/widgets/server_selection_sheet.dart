import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/color_palette.dart';
import '../models/server_item.dart';
import '../providers/stream_resolution_provider.dart';

/// D-pad accessible bottom sheet for selecting streaming servers.
/// Clearly differentiates: Ready, Loading, Not yet resolved, and Failed.
class ServerSelectionSheet extends ConsumerStatefulWidget {
  final Duration currentPosition;
  final void Function(int serverIndex) onSelectServer;
  final VoidCallback onOpenLinks;

  const ServerSelectionSheet({
    super.key,
    required this.currentPosition,
    required this.onSelectServer,
    required this.onOpenLinks,
  });

  static Future<void> show({
    required BuildContext context,
    required Duration currentPosition,
    required void Function(int serverIndex) onSelectServer,
    required VoidCallback onOpenLinks,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ServerSelectionSheet(
        currentPosition: currentPosition,
        onSelectServer: onSelectServer,
        onOpenLinks: onOpenLinks,
      ),
    );
  }

  @override
  ConsumerState<ServerSelectionSheet> createState() =>
      _ServerSelectionSheetState();
}

class _ServerSelectionSheetState extends ConsumerState<ServerSelectionSheet> {
  final FocusNode _firstItemFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _firstItemFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _firstItemFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(streamResolutionControllerProvider);
    final servers = state.servers;
    final selectedIdx = state.selectedServerIndex;

    return FocusScope(
      autofocus: true,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: ColorPalette.canvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sheet Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.dns_rounded,
                      color: ColorPalette.primaryGreen,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Streaming Servers',
                      style: TextStyle(
                        color: ColorPalette.fontWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (state.selectedServer != null &&
                        state.selectedServer!.sources.isNotEmpty)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ColorPalette.primaryGreen,
                          side: const BorderSide(
                            color: ColorPalette.primaryGreen,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onOpenLinks();
                        },
                        icon: const Icon(Icons.link_rounded, size: 16),
                        label: Text(
                          'Links (${state.selectedServer!.sources.length})',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close, color: ColorPalette.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(color: ColorPalette.ghostBorder, height: 1),

              // Server List
              if (servers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'No servers available for this content.',
                      style: TextStyle(color: ColorPalette.textMuted),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    itemCount: servers.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final server = servers[index];
                      final isSelected = index == selectedIdx;
                      final isFirst = index == 0;

                      return _ServerTile(
                        focusNode: isFirst ? _firstItemFocusNode : null,
                        server: server,
                        isSelected: isSelected,
                        onTap: () {
                          widget.onSelectServer(index);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServerTile extends StatefulWidget {
  final FocusNode? focusNode;
  final ServerItem server;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServerTile({
    this.focusNode,
    required this.server,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ServerTile> createState() => _ServerTileState();
}

class _ServerTileState extends State<_ServerTile> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final server = widget.server;
    final isSelected = widget.isSelected;

    Widget statusBadge;
    switch (server.resolutionStatus) {
      case ServerResolutionStatus.ready:
        final count = server.sources.where((s) => !s.isFailed).length;
        statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: ColorPalette.primaryGreen.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: ColorPalette.primaryGreen.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 13,
                color: ColorPalette.primaryGreen,
              ),
              const SizedBox(width: 4),
              Text(
                'Ready ($count)',
                style: const TextStyle(
                  color: ColorPalette.primaryGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
        break;

      case ServerResolutionStatus.loading:
        statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.amber,
                ),
              ),
              SizedBox(width: 5),
              Text(
                'Loading...',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
        break;

      case ServerResolutionStatus.failed:
        statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 13,
                color: Colors.redAccent,
              ),
              SizedBox(width: 4),
              Text(
                'Failed',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
        break;

      case ServerResolutionStatus.idle:
        statusBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Not Resolved',
            style: TextStyle(
              color: ColorPalette.textMuted,
              fontSize: 11,
            ),
          ),
        );
        break;
    }

    final isHighlighted = _isFocused || isSelected;

    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (focused) {
        setState(() {
          _isFocused = focused;
        });
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? ColorPalette.primaryGreen.withValues(alpha: 0.12)
                  : (_isFocused ? Colors.white12 : Colors.white.withValues(alpha: 0.04)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isFocused
                    ? ColorPalette.primaryGreen
                    : (isSelected
                        ? ColorPalette.primaryGreen.withValues(alpha: 0.5)
                        : Colors.transparent),
                width: _isFocused ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 20,
                  color: isSelected
                      ? ColorPalette.primaryGreen
                      : ColorPalette.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              server.name,
                              style: TextStyle(
                                color: isHighlighted
                                    ? ColorPalette.fontWhite
                                    : ColorPalette.fontWhite.withValues(alpha: 0.9),
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (server.quality != null &&
                              server.quality!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                server.quality!,
                                style: const TextStyle(
                                  color: ColorPalette.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (server.errorMessage != null &&
                          server.resolutionStatus ==
                              ServerResolutionStatus.failed) ...[
                        const SizedBox(height: 2),
                        Text(
                          server.errorMessage!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                statusBadge,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
