import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sparrow/shared/responsive_utils.dart';
import 'package:sparrow/theme/color_palette.dart';

/// Riverpod notifier for managing the selected audio track.
/// Defaults strictly to "Original Audio".
class SelectedAudioNotifier extends Notifier<String> {
  @override
  String build() => 'Original Audio';

  void setAudio(String audio) => state = audio;
}

final selectedAudioTrackProvider =
    NotifierProvider<SelectedAudioNotifier, String>(SelectedAudioNotifier.new);

/// Audio option descriptor with metadata subtitles and telemetry badges.
class AudioOption {
  final String label;
  final String description;
  final String bitrate;
  final IconData icon;

  const AudioOption({
    required this.label,
    required this.description,
    required this.bitrate,
    required this.icon,
  });
}

const List<AudioOption> kAudioOptions = [
  AudioOption(
    label: 'Hindi',
    description: '5.1 Surround • Clear Voice Dub',
    bitrate: '384 kbps',
    icon: Icons.graphic_eq_rounded,
  ),
  AudioOption(
    label: 'Original Audio',
    description: 'English Dolby Atmos • Master TrueHD',
    bitrate: '768 kbps',
    icon: Icons.volume_up_rounded,
  ),
  AudioOption(
    label: 'Unverified',
    description: 'Community Sync • Direct Bitstream',
    bitrate: 'Variable',
    icon: Icons.sync_alt_rounded,
  ),
];

/// A real, accessible Audio Selection Dropdown matching the Sparrow design system.
///
/// Collapsed State:
/// - Compact, rounded pill/box with headphones icon.
/// - Currently selected audio title.
/// - Downward chevron and emerald status dot.
/// - Dark obsidian background with subtle border.
///
/// Expanded State:
/// - Floating popup dropdown menu anchored directly to the button.
/// - Lists all three options: "Hindi", "Original Audio", "Unverified".
/// - Highlights the active selection with an emerald checkmark and neon tint.
/// - Dismisses instantly upon selection and updates the collapsed state.
class MovieAudioDropdown extends ConsumerStatefulWidget {
  final ValueChanged<String>? onAudioChanged;
  final bool isTvOrDesktop;

  const MovieAudioDropdown({
    super.key,
    this.onAudioChanged,
    this.isTvOrDesktop = false,
  });

  @override
  ConsumerState<MovieAudioDropdown> createState() => _MovieAudioDropdownState();
}

class _MovieAudioDropdownState extends ConsumerState<MovieAudioDropdown> {
  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final selectedAudio = ref.watch(selectedAudioTrackProvider);
    final isDesktop = widget.isTvOrDesktop || responsive.isTvOrDesktop;

    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: ColorPalette.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsive.radius(16)),
            side: BorderSide(
              color: ColorPalette.primaryGreen.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          elevation: 16,
        ),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Select Audio Stream',
        initialValue: selectedAudio,
        offset: const Offset(0, 56),
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 380),
        position: PopupMenuPosition.under,
        onSelected: (String newAudio) {
          ref.read(selectedAudioTrackProvider.notifier).setAudio(newAudio);
          widget.onAudioChanged?.call(newAudio);
        },
        itemBuilder: (BuildContext context) {
          return kAudioOptions.map((AudioOption option) {
            final isSelected = option.label == selectedAudio;
            return PopupMenuItem<String>(
              value: option.label,
              padding: EdgeInsets.symmetric(
                horizontal: responsive.scale(12, min: 10, max: 16),
                vertical: 8,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ColorPalette.primaryGreen.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(responsive.radius(10)),
                  border: isSelected
                      ? Border.all(
                          color: ColorPalette.primaryGreen.withValues(
                            alpha: 0.4,
                          ),
                          width: 1,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    // Icon Container
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? ColorPalette.primaryGreen
                            : ColorPalette.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        option.icon,
                        size: 18,
                        color: isSelected
                            ? Colors.black
                            : ColorPalette.fontWhite,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Label & Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              Text(
                                option.label,
                                style: TextStyle(
                                  color: isSelected
                                      ? ColorPalette.primaryGreen
                                      : ColorPalette.fontWhite,
                                  fontSize: responsive.sp(14, min: 12, max: 16),
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ColorPalette.primaryGreen,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            option.description,
                            style: TextStyle(
                              color: ColorPalette.textMuted,
                              fontSize: responsive.sp(11, min: 9.5, max: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Telemetry Bitrate Tag & Checkmark
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          option.bitrate,
                          style: TextStyle(
                            color: isSelected
                                ? ColorPalette.primaryGreen
                                : ColorPalette.textMuted,
                            fontSize: responsive.sp(10, min: 9, max: 11),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isSelected)
                          const Padding(
                            padding: EdgeInsets.only(top: 3),
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: ColorPalette.primaryGreen,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList();
        },
        // Collapsed State Control Trigger
        child: Container(
          height: isDesktop ? 50 : 46,
          padding: EdgeInsets.symmetric(
            horizontal: responsive.scale(12, min: 10, max: 16),
          ),
          decoration: BoxDecoration(
            color: ColorPalette.surfaceContainerHigh.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(
              isDesktop ? 25 : responsive.radius(12),
            ),
            border: Border.all(
              color: ColorPalette.primaryGreen.withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: ColorPalette.primaryGreen.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: isDesktop ? MainAxisSize.min : MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: ColorPalette.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.headphones_rounded,
                        size: 17,
                        color: ColorPalette.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Audio: $selectedAudio',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ColorPalette.fontWhite,
                          fontSize: responsive.sp(13, min: 11.5, max: 15),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: ColorPalette.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.expand_more_rounded,
                    size: 20,
                    color: ColorPalette.textMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
