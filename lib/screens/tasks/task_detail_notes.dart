import 'package:flutter/material.dart';

class TaskDetailNotesSection extends StatefulWidget {
  final String text;
  final Color accentColor;
  final int collapsedMaxLines;

  const TaskDetailNotesSection({
    super.key,
    required this.text,
    required this.accentColor,
    this.collapsedMaxLines = 7,
  });

  @override
  State<TaskDetailNotesSection> createState() => _TaskDetailNotesSectionState();
}

class _TaskDetailNotesSectionState extends State<TaskDetailNotesSection> {
  bool _expanded = false;

  bool get _isLongNote {
    final trimmed = widget.text.trim();
    final lineCount = '\n'.allMatches(trimmed).length + 1;

    return trimmed.length > 360 || lineCount > widget.collapsedMaxLines;
  }

  @override
  void didUpdateWidget(TaskDetailNotesSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.text != widget.text) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final longNote = _isLongNote;

    final noteAccent = Color.lerp(
      const Color(0xFFB7832D),
      widget.accentColor,
      0.08,
    )!;

    final cardColor = Color.alphaBlend(
      noteAccent.withValues(
        alpha: brightness == Brightness.dark ? 0.10 : 0.055,
      ),
      colorScheme.surface,
    );

    final contentColor = Color.alphaBlend(
      noteAccent.withValues(
        alpha: brightness == Brightness.dark ? 0.09 : 0.075,
      ),
      colorScheme.surfaceContainerLow,
    );

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.30),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.alphaBlend(
                    noteAccent.withValues(
                      alpha: brightness == Brightness.dark ? 0.18 : 0.15,
                    ),
                    colorScheme.surface,
                  ),
                ),
                child: Icon(
                  Icons.description_outlined,
                  size: 24,
                  color: noteAccent,
                ),
              ),
              const SizedBox(width: 13),
              Text(
                'Note',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: contentColor,
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.fromLTRB(15, 13, 15, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectionArea(
                  child: Text(
                    widget.text.trim(),
                    key: const Key('task_detail_note_text'),
                    maxLines: longNote && !_expanded
                        ? widget.collapsedMaxLines
                        : null,
                    overflow: longNote && !_expanded
                        ? TextOverflow.fade
                        : TextOverflow.visible,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.52,
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                ),
                if (longNote) ...[
                  const SizedBox(height: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _expanded = !_expanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _expanded ? 'Mostra meno' : 'Mostra tutto',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: noteAccent,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _expanded ? Icons.expand_less : Icons.expand_more,
                              size: 18,
                              color: noteAccent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
