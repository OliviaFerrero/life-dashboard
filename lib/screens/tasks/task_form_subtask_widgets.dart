part of 'task_form_page.dart';

class _SubtaskFormRow
    extends StatelessWidget {
  final TaskSubtask subtask;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SubtaskFormRow({
    super.key,
    required this.subtask,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Material(
      color:
          Colors.transparent,
      child: InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        child: Padding(
          padding:
              const EdgeInsets
                  .symmetric(
            vertical: 8,
          ),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index:
                    index,
                child: Padding(
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    2,
                    10,
                    12,
                    10,
                  ),
                  child: Icon(
                    Icons
                        .drag_indicator,
                    size: 20,
                    color:
                        colorScheme
                            .onSurfaceVariant,
                  ),
                ),
              ),

              Expanded(
                child: Text(
                  subtask.title,
                  style:
                      Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            fontWeight:
                                FontWeight
                                    .w500,
                          ),
                ),
              ),

              IconButton(
                tooltip:
                    'Rimuovi sottoattività',
                visualDensity:
                    VisualDensity
                        .compact,
                onPressed:
                    onDelete,
                icon:
                    Icon(
                  Icons.close,
                  size: 18,
                  color:
                      colorScheme
                          .onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubtaskTitleSheet
    extends StatefulWidget {
  final String title;
  final String actionLabel;
  final String initialTitle;

  const _SubtaskTitleSheet({
    required this.title,
    required this.actionLabel,
    required this.initialTitle,
  });

  @override
  State<_SubtaskTitleSheet>
      createState() =>
          _SubtaskTitleSheetState();
}

class _SubtaskTitleSheetState
    extends State<_SubtaskTitleSheet> {
  late final TextEditingController
      _controller;

  String? _errorText;

  @override
  void initState() {
    super.initState();

    _controller =
        TextEditingController(
      text:
          widget.initialTitle,
    );

    _controller.selection =
        TextSelection.collapsed(
      offset:
          _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final value =
        _controller.text.trim();

    if (value.isEmpty) {
      setState(() {
        _errorText =
            'Inserisci un titolo.';
      });
      return;
    }

    FocusManager
        .instance
        .primaryFocus
        ?.unfocus();

    Navigator.pop(
      context,
      value,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Padding(
      padding:
          EdgeInsets.only(
        bottom:
            MediaQuery.viewInsetsOf(
          context,
        ).bottom,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          margin:
              const EdgeInsets
                  .fromLTRB(
            12,
            0,
            12,
            12,
          ),
          padding:
              const EdgeInsets
                  .fromLTRB(
            20,
            18,
            20,
            18,
          ),
          decoration:
              BoxDecoration(
            color:
                colorScheme.surface,
            borderRadius:
                BorderRadius.circular(
              24,
            ),
            border:
                Border.all(
              color:
                  colorScheme
                      .outlineVariant
                      .withValues(
                alpha:
                    0.55,
              ),
            ),
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Text(
                widget.title,
                style:
                    Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight:
                              FontWeight
                                  .w700,
                        ),
              ),

              const SizedBox(
                height: 18,
              ),

              TextField(
                controller:
                    _controller,
                autofocus:
                    true,
                textInputAction:
                    TextInputAction.done,
                onSubmitted:
                    (_) {
                  _confirm();
                },
                decoration:
                    InputDecoration(
                  hintText:
                      'Titolo sottoattività',
                  errorText:
                      _errorText,
                  border:
                      const UnderlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 22,
              ),

              SizedBox(
                width:
                    double.infinity,
                child:
                    FilledButton(
                  onPressed:
                      _confirm,
                  child:
                      Text(
                    widget.actionLabel,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

