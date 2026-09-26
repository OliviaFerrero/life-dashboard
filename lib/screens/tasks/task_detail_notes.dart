import 'package:flutter/material.dart';

class TaskDetailNotesSection
    extends StatefulWidget {
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
  State<TaskDetailNotesSection>
      createState() =>
          _TaskDetailNotesSectionState();
}

class _TaskDetailNotesSectionState
    extends State<TaskDetailNotesSection> {
  bool _expanded = false;

  bool get _isLongNote {
    final trimmed =
        widget.text.trim();

    final lineCount =
        '\n'.allMatches(
      trimmed,
    ).length +
            1;

    return trimmed.length >
            360 ||
        lineCount >
            widget.collapsedMaxLines;
  }

  @override
  void didUpdateWidget(
    TaskDetailNotesSection oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    if (oldWidget.text !=
        widget.text) {
      _expanded =
          false;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final longNote =
        _isLongNote;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'NOTE',
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(
                color: colorScheme
                    .onSurfaceVariant,
                fontWeight:
                    FontWeight.w800,
                letterSpacing:
                    1,
              ),
        ),
        const SizedBox(
          height:
              10,
        ),
        Container(
          decoration:
              BoxDecoration(
            border:
                Border(
              left:
                  BorderSide(
                color: widget
                    .accentColor
                    .withValues(
                  alpha:
                      0.7,
                ),
                width:
                    2,
              ),
            ),
          ),
          padding:
              const EdgeInsets.only(
            left:
                14,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              SelectionArea(
                child: Text(
                  widget.text.trim(),
                  key:
                      const Key(
                    'task_detail_note_text',
                  ),
                  maxLines:
                      longNote &&
                              !_expanded
                          ? widget
                              .collapsedMaxLines
                          : null,
                  overflow:
                      longNote &&
                              !_expanded
                          ? TextOverflow.fade
                          : TextOverflow.visible,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                        height:
                            1.55,
                      ),
                ),
              ),
              if (longNote) ...[
                const SizedBox(
                  height:
                      10,
                ),
                Material(
                  color:
                      Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _expanded =
                            !_expanded;
                      });
                    },
                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        vertical:
                            6,
                        horizontal:
                            2,
                      ),
                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Text(
                            _expanded
                                ? 'Mostra meno'
                                : 'Mostra tutto',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colorScheme
                                      .primary,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                          ),
                          const SizedBox(
                            width:
                                4,
                          ),
                          Icon(
                            _expanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size:
                                18,
                            color:
                                colorScheme.primary,
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
    );
  }
}
