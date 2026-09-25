part of 'task_form_page.dart';

class _CategorySelectionResult {
  final String? categoryId;

  const _CategorySelectionResult(
    this.categoryId,
  );
}

class _CategoryPickerSheet
    extends StatelessWidget {
  final CategoryRepository categoryRepository;
  final String? selectedCategoryId;

  const _CategoryPickerSheet({
    required this.categoryRepository,
    required this.selectedCategoryId,
  });

  Future<void> _openManagement(
    BuildContext context,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CategoryManagementPage(
          categoryRepository:
              categoryRepository,
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return SafeArea(
      top: false,

      child: Container(
        constraints:
            BoxConstraints(
          maxHeight:
              MediaQuery.sizeOf(
                    context,
                  ).height *
                  0.78,
        ),

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
          12,
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
              alpha: 0.55,
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
              'CATEGORIA',
              style:
                  Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(
                        color:
                            colorScheme
                                .onSurfaceVariant,
                        fontWeight:
                            FontWeight
                                .w800,
                        letterSpacing:
                            1.0,
                      ),
            ),

            const SizedBox(
              height: 8,
            ),

            _CategoryPickerRow(
              label:
                  'Nessuna categoria',
              icon:
                  Icons
                      .remove_circle_outline,
              color:
                  colorScheme
                      .onSurfaceVariant,
              selected:
                  selectedCategoryId ==
                      null,
              onTap: () {
                Navigator.pop(
                  context,
                  const _CategorySelectionResult(
                    null,
                  ),
                );
              },
            ),

            Divider(
              height: 1,
              indent: 46,
              color:
                  colorScheme
                      .outlineVariant
                      .withValues(
                alpha: 0.45,
              ),
            ),

            Flexible(
              child: StreamBuilder<
                  List<TaskCategory>>(
                stream:
                    categoryRepository
                        .watchAllCategories(),

                builder:
                    (context, snapshot) {
                  if (snapshot.hasError) {
                    return Padding(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 18,
                      ),
                      child: Text(
                        'Impossibile caricare '
                        'le categorie.',
                        style:
                            Theme.of(
                          context,
                        )
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      colorScheme
                                          .error,
                                ),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Padding(
                      padding:
                          EdgeInsets
                              .symmetric(
                        vertical: 24,
                      ),
                      child: Center(
                        child:
                            CircularProgressIndicator(),
                      ),
                    );
                  }

                  final categories =
                      snapshot.data!;

                  if (categories.isEmpty) {
                    return Padding(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 18,
                      ),
                      child: Text(
                        'Non hai ancora '
                        'categorie personalizzate.',
                        style:
                            Theme.of(
                          context,
                        )
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      colorScheme
                                          .onSurfaceVariant,
                                ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap:
                        true,
                    padding:
                        EdgeInsets.zero,
                    itemCount:
                        categories.length,
                    separatorBuilder:
                        (_, _) {
                      return Divider(
                        height: 1,
                        indent: 46,
                        color:
                            colorScheme
                                .outlineVariant
                                .withValues(
                          alpha:
                              0.45,
                        ),
                      );
                    },
                    itemBuilder:
                        (context, index) {
                      final category =
                          categories[index];

                      return _CategoryPickerRow(
                        label:
                            category.name,
                        icon:
                            taskCategoryIcon(
                          category.iconKey,
                        ),
                        color:
                            Color(
                          category.colorValue,
                        ),
                        selected:
                            selectedCategoryId ==
                                category.id,
                        onTap: () {
                          Navigator.pop(
                            context,
                            _CategorySelectionResult(
                              category.id,
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            Divider(
              height: 1,
              color:
                  colorScheme
                      .outlineVariant
                      .withValues(
                alpha: 0.55,
              ),
            ),

            Material(
              color:
                  Colors.transparent,

              child: InkWell(
                onTap: () {
                  _openManagement(
                    context,
                  );
                },
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),

                child: Padding(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 14,
                  ),

                  child: Row(
                    children: [
                      SizedBox(
                        width: 34,
                        child: Icon(
                          Icons
                              .tune_outlined,
                          size: 20,
                          color:
                              colorScheme
                                  .primary,
                        ),
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      Expanded(
                        child: Text(
                          'Gestisci categorie',
                          style:
                              Theme.of(
                            context,
                          )
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color:
                                        colorScheme
                                            .primary,
                                    fontWeight:
                                        FontWeight
                                            .w700,
                                  ),
                        ),
                      ),

                      Icon(
                        Icons
                            .chevron_right,
                        size: 19,
                        color:
                            colorScheme
                                .primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPickerRow
    extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryPickerRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
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
            vertical: 13,
          ),

          child: Row(
            children: [
              SizedBox(
                width: 34,
                child: Align(
                  alignment:
                      Alignment
                          .centerLeft,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration:
                        BoxDecoration(
                      color:
                          color.withValues(
                        alpha: 0.11,
                      ),
                      shape:
                          BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 17,
                      color:
                          color,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Text(
                  label,
                  style:
                      Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            fontWeight:
                                selected
                                    ? FontWeight
                                        .w700
                                    : FontWeight
                                        .w500,
                          ),
                ),
              ),

              if (selected)
                Icon(
                  Icons.check,
                  size: 19,
                  color:
                      colorScheme
                          .primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

