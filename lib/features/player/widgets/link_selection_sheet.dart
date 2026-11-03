import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/color_palette.dart';
import '../models/resolved_source.dart';
import '../providers/stream_resolution_provider.dart';

/// D-pad accessible bottom sheet for selecting among multiple links of the active server.
class LinkSelectionSheet extends ConsumerStatefulWidget {
  final Duration currentPosition;
  final void Function(int sourceIndex) onSelectSource;

  const LinkSelectionSheet({
    super.key,
    required this.currentPosition,
    required this.onSelectSource,
  });

  static Future<void> show({
    required BuildContext context,
    required Duration currentPosition,
    required void Function(int sourceIndex) onSelectSource,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => LinkSelectionSheet(
        currentPosition: currentPosition,
        onSelectSource: onSelectSource,
      ),
    );
  }

  @override
  ConsumerState<LinkSelectionSheet> createState() => _LinkSelectionSheetState();
}

class _LinkSelectionSheetState extends ConsumerState<LinkSelectionSheet> {
  final FocusNode _firstFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _firstFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _firstFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(streamResolutionControllerProvider);
    final server = state.selectedServer;
    final sources = server?.sources ?? [];
    final selectedSourceIdx = state.selectedSourceIndex ?? 0;

    return FocusScope(
      autofocus: true,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
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
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.link_rounded,
                      color: ColorPalette.primaryGreen,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available Links',
                          style: TextStyle(
                            color: ColorPalette.fontWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (server != null)
                          Text(
                            server.name,
                            style: const TextStyle(
                              color: ColorPalette.textMuted,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: ColorPalette.textMuted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(color: ColorPalette.ghostBorder, height: 1),

              if (sources.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'No alternative links for this server.',
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
                    itemCount: sources.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final source = sources[index];
                      final isSelected = index == selectedSourceIdx;
                      final isFirst = index == 0;

                      return _LinkTile(
                        focusNode: isFirst ? _firstFocusNode : null,
                        source: source,
                        index: index + 1,
                        isSelected: isSelected,
                        onTap: () {
                          widget.onSelectSource(index);
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

class _LinkTile extends StatefulWidget {
  final FocusNode? focusNode;
  final ResolvedSource source;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  const _LinkTile({
    this.focusNode,
    required this.source,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_LinkTile> createState() => _LinkTileState();
}

class _LinkTileState extends State<_LinkTile> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final source = widget.source;
    final isSelected = widget.isSelected;
    final isFailed = source.isFailed;

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
                      ? Icons.check_circle_rounded
                      : (isFailed
                          ? Icons.cancel_outlined
                          : Icons.radio_button_off),
                  size: 20,
                  color: isSelected
                      ? ColorPalette.primaryGreen
                      : (isFailed ? Colors.redAccent : ColorPalette.textMuted),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Link ${widget.index}: ${source.displayName}',
                        style: TextStyle(
                          color: isFailed
                              ? ColorPalette.textMuted
                              : ColorPalette.fontWhite,
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          decoration: isFailed ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (source.quality != null && source.quality!.isNotEmpty)
                        Text(
                          source.quality!,
                          style: const TextStyle(
                            color: ColorPalette.textMuted,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                if (source.languageBadge.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: source.language == SourceLanguage.hindi
                          ? Colors.orange.withValues(alpha: 0.15)
                          : (source.language == SourceLanguage.multi
                              ? Colors.purple.withValues(alpha: 0.15)
                              : Colors.blue.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: source.language == SourceLanguage.hindi
                            ? Colors.orangeAccent.withValues(alpha: 0.6)
                            : (source.language == SourceLanguage.multi
                                ? Colors.purpleAccent.withValues(alpha: 0.6)
                                : Colors.lightBlueAccent.withValues(alpha: 0.6)),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      source.languageBadge,
                      style: TextStyle(
                        color: source.language == SourceLanguage.hindi
                            ? Colors.orangeAccent
                            : (source.language == SourceLanguage.multi
                                ? Colors.purpleAccent
                                : Colors.lightBlueAccent),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (isFailed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Unplayable',
                      style: TextStyle(color: Colors.redAccent, fontSize: 10),
                    ),
                  )
                else if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: ColorPalette.primaryGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        color: ColorPalette.primaryGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
