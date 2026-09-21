import 'package:flutter/material.dart';

import '../../models/task_category.dart';
import '../../repositories/category_repository.dart';
import '../../utils/task_category_icons.dart';

class CategoryManagementPage
    extends StatelessWidget {
  final CategoryRepository categoryRepository;

  const CategoryManagementPage({
    super.key,
    required this.categoryRepository,
  });

  Future<void> _openEditor(
    BuildContext context, {
    TaskCategory? category,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CategoryEditPage(
          categoryRepository:
              categoryRepository,
          initialCategory:
              category,
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

    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Categorie',
        ),
        actions: [
          IconButton(
            tooltip:
                'Nuova categoria',
            onPressed: () {
              _openEditor(
                context,
              );
            },
            icon:
                const Icon(
              Icons.add,
            ),
          ),
          const SizedBox(
            width: 8,
          ),
        ],
      ),

      body: StreamBuilder<
          List<TaskCategory>>(
        stream:
            categoryRepository
                .watchAllCategories(),

        builder:
            (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets
                        .all(
                  24,
                ),
                child: Text(
                  'Errore nel caricamento '
                  'delle categorie:\n'
                  '${snapshot.error}',
                  textAlign:
                      TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final categories =
              snapshot.data!;

          return ListView(
            padding:
                const EdgeInsets
                    .fromLTRB(
              24,
              18,
              24,
              44,
            ),

            children: [
              Text(
                'Organizza le attività '
                'con un’identità visiva '
                'personale.',
                style:
                    Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight:
                              FontWeight
                                  .w700,
                          letterSpacing:
                              -0.4,
                        ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                'Nome, colore e icona '
                'possono essere cambiati '
                'in qualsiasi momento.',
                style:
                    Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(
                          color:
                              colorScheme
                                  .onSurfaceVariant,
                          height:
                              1.45,
                        ),
              ),

              const SizedBox(
                height: 30,
              ),

              _NoneCategoryInfo(),

              const SizedBox(
                height: 20,
              ),

              if (categories.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 24,
                  ),
                  child: Text(
                    'Non ci sono categorie. '
                    'Usa + per crearne una.',
                    style:
                        Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(
                              color:
                                  colorScheme
                                      .onSurfaceVariant,
                            ),
                  ),
                )
              else
                for (int i = 0;
                    i <
                        categories.length;
                    i++) ...[
                  _CategoryManagementRow(
                    category:
                        categories[i],
                    onTap: () {
                      _openEditor(
                        context,
                        category:
                            categories[i],
                      );
                    },
                  ),

                  if (i !=
                      categories.length -
                          1)
                    Divider(
                      indent:
                          46,
                      color:
                          colorScheme
                              .outlineVariant
                              .withValues(
                        alpha:
                            0.5,
                      ),
                    ),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _NoneCategoryInfo
    extends StatelessWidget {
  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration:
              BoxDecoration(
            color:
                colorScheme
                    .onSurfaceVariant
                    .withValues(
              alpha:
                  0.08,
            ),
            shape:
                BoxShape.circle,
          ),
          child: Icon(
            Icons
                .remove_circle_outline,
            size: 18,
            color:
                colorScheme
                    .onSurfaceVariant,
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Text(
                'Nessuna categoria',
                style:
                    Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                'Opzione sempre disponibile',
                style:
                    Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color:
                              colorScheme
                                  .onSurfaceVariant,
                        ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryManagementRow
    extends StatelessWidget {
  final TaskCategory category;
  final VoidCallback onTap;

  const _CategoryManagementRow({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final color =
        Color(
      category.colorValue,
    );

    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Material(
      color:
          Colors.transparent,

      child: InkWell(
        onTap:
            onTap,

        child: Padding(
          padding:
              const EdgeInsets
                  .symmetric(
            vertical: 14,
          ),

          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration:
                    BoxDecoration(
                  color:
                      color.withValues(
                    alpha:
                        0.12,
                  ),
                  shape:
                      BoxShape.circle,
                ),
                child: Icon(
                  taskCategoryIcon(
                    category.iconKey,
                  ),
                  size: 18,
                  color:
                      color,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Text(
                  category.name,
                  style:
                      Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                ),
              ),

              Icon(
                Icons
                    .chevron_right,
                size: 19,
                color:
                    colorScheme
                        .onSurfaceVariant
                        .withValues(
                  alpha:
                      0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryEditPage
    extends StatefulWidget {
  final CategoryRepository categoryRepository;
  final TaskCategory? initialCategory;

  const CategoryEditPage({
    super.key,
    required this.categoryRepository,
    this.initialCategory,
  });

  @override
  State<CategoryEditPage>
      createState() =>
          _CategoryEditPageState();
}

class _CategoryEditPageState
    extends State<CategoryEditPage> {
  static const _palette = [
    // Viola / lilla
    0xFF6750A4,
    0xFF7B61A8,
    0xFF8F6BB3,
    0xFFA06BC0,
    0xFF7657B5,
    0xFF5B4FA8,

    // Blu
    0xFF4F7396,
    0xFF456FA3,
    0xFF3D6FB4,
    0xFF4A80C1,
    0xFF397B9A,
    0xFF365D8D,

    // Ciano / teal
    0xFF3B8EA5,
    0xFF2F7F7A,
    0xFF3B8C83,
    0xFF4A9A8F,
    0xFF2F6F73,

    // Verdi
    0xFF5B8F72,
    0xFF4E8A67,
    0xFF6C8C4E,
    0xFF7C9B55,
    0xFF3F6B59,
    0xFF527A4F,

    // Gialli / ocra
    0xFF8A8D3B,
    0xFFA28E3E,
    0xFFB89A47,
    0xFFC3A34B,

    // Arancio
    0xFFA97948,
    0xFFC17B3F,
    0xFFCE7A3C,
    0xFFD78948,
    0xFFB6653E,

    // Rossi / corallo
    0xFFB66B73,
    0xFFC65B61,
    0xFFC94F5E,
    0xFFB85252,
    0xFFD46A5F,

    // Rosa / magenta
    0xFFB04F87,
    0xFFC15A92,
    0xFF9B5B8F,
    0xFF8F5EA8,

    // Marroni
    0xFF795548,
    0xFF8D6652,
    0xFF6D5145,

    // Neutri / slate
    0xFF6D6F78,
    0xFF5F6670,
    0xFF455A64,
    0xFF59636B,
  ];

  late final TextEditingController
      _nameController;

  late int _selectedColorValue;
  late String _selectedIconKey;

  String? _nameError;
  bool _saving = false;

  bool get _isEditing =>
      widget.initialCategory !=
      null;

  @override
  void initState() {
    super.initState();

    final category =
        widget.initialCategory;

    _nameController =
        TextEditingController(
      text:
          category?.name ??
              '',
    );

    _selectedColorValue =
        category?.colorValue ??
            _palette.first;

    _selectedIconKey =
        category?.iconKey ??
            'label_outline';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List<int> get _visiblePalette {
    if (_palette.contains(
      _selectedColorValue,
    )) {
      return _palette;
    }

    return [
      _selectedColorValue,
      ..._palette,
    ];
  }

  Future<void> _save() async {
    FocusManager
        .instance
        .primaryFocus
        ?.unfocus();

    final name =
        _nameController.text
            .trim();

    if (name.isEmpty) {
      setState(() {
        _nameError =
            'Inserisci un nome.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _nameError = null;
    });

    final categories =
        await widget
            .categoryRepository
            .getAllCategories();

    final duplicate =
        categories.any(
      (category) =>
          category.id !=
              widget
                  .initialCategory
                  ?.id &&
          category.name
                  .trim()
                  .toLowerCase() ==
              name.toLowerCase(),
    );

    if (duplicate) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
        _nameError =
            'Esiste già una categoria '
            'con questo nome.';
      });
      return;
    }

    if (_isEditing) {
      final updated =
          widget.initialCategory!
              .copyWith(
        name:
            name,
        colorValue:
            _selectedColorValue,
        iconKey:
            _selectedIconKey,
      );

      await widget
          .categoryRepository
          .updateCategory(
        updated,
      );
    } else {
      var nextSortOrder = 0;

      for (final category
          in categories) {
        if (category.sortOrder >=
            nextSortOrder) {
          nextSortOrder =
              category.sortOrder +
                  1;
        }
      }

      final category =
          TaskCategory(
        id:
            'category_'
            '${DateTime.now().microsecondsSinceEpoch}',
        name:
            name,
        colorValue:
            _selectedColorValue,
        iconKey:
            _selectedIconKey,
        sortOrder:
            nextSortOrder,
      );

      await widget
          .categoryRepository
          .addCategory(
        category,
      );
    }

    if (!mounted) {
      return;
    }

    Navigator.pop(
      context,
      true,
    );
  }

  Future<void> _delete() async {
    final category =
        widget.initialCategory;

    if (category == null) {
      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title:
              const Text(
            'Eliminare categoria?',
          ),
          content: Text(
            'Vuoi eliminare '
            '"${category.name}"?\n\n'
            'Le attività che la usano '
            'non verranno eliminate: '
            'passeranno a '
            '"Nessuna categoria".',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
                  const Text(
                'Annulla',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style:
                  FilledButton
                      .styleFrom(
                backgroundColor:
                    Theme.of(
                  context,
                )
                        .colorScheme
                        .error,
                foregroundColor:
                    Theme.of(
                  context,
                )
                        .colorScheme
                        .onError,
              ),
              child:
                  const Text(
                'Elimina',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await widget
        .categoryRepository
        .deleteCategory(
      category.id,
    );

    if (!mounted) {
      return;
    }

    Navigator.pop(
      context,
      true,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    final selectedColor =
        Color(
      _selectedColorValue,
    );

    return Scaffold(
      appBar: AppBar(
        title:
            const SizedBox
                .shrink(),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip:
                  'Elimina categoria',
              onPressed:
                  _saving
                      ? null
                      : _delete,
              color:
                  colorScheme.error,
              icon:
                  const Icon(
                Icons
                    .delete_outline,
              ),
            ),
          const SizedBox(
            width: 8,
          ),
        ],
      ),

      body: ListView(
        keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior
                .onDrag,
        padding:
            const EdgeInsets
                .fromLTRB(
          24,
          8,
          24,
          120,
        ),

        children: [
          Text(
            _isEditing
                ? 'Modifica categoria'
                : 'Nuova categoria',
            style:
                Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(
                      fontWeight:
                          FontWeight
                              .w700,
                      letterSpacing:
                          -0.7,
                    ),
          ),

          const SizedBox(
            height: 28,
          ),

          Row(
            crossAxisAlignment:
                CrossAxisAlignment
                    .center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                    BoxDecoration(
                  color:
                      selectedColor
                          .withValues(
                    alpha:
                        0.12,
                  ),
                  shape:
                      BoxShape.circle,
                ),
                child: Icon(
                  taskCategoryIcon(
                    _selectedIconKey,
                  ),
                  size: 24,
                  color:
                      selectedColor,
                ),
              ),

              const SizedBox(
                width: 16,
              ),

              Expanded(
                child: TextFormField(
                  controller:
                      _nameController,
                  autofocus:
                      !_isEditing,
                  textCapitalization:
                      TextCapitalization
                          .sentences,
                  decoration:
                      InputDecoration(
                    hintText:
                        'Nome categoria',
                    errorText:
                        _nameError,
                    border:
                        InputBorder.none,
                    enabledBorder:
                        InputBorder.none,
                    focusedBorder:
                        InputBorder.none,
                    contentPadding:
                        EdgeInsets.zero,
                  ),
                  style:
                      Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                  onChanged:
                      (_) {
                    if (_nameError !=
                        null) {
                      setState(() {
                        _nameError =
                            null;
                      });
                    }
                  },
                  onFieldSubmitted:
                      (_) {
                    _save();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          Divider(
            color:
                colorScheme
                    .outlineVariant
                    .withValues(
              alpha:
                  0.65,
            ),
          ),

          const SizedBox(
            height: 30,
          ),

          const _EditorSectionLabel(
            text:
                'COLORE',
          ),

          const SizedBox(
            height: 16,
          ),

          Wrap(
            spacing:
                14,
            runSpacing:
                14,
            children: [
              for (final value
                  in _visiblePalette)
                _ColorChoice(
                  color:
                      Color(value),
                  selected:
                      value ==
                          _selectedColorValue,
                  onTap: () {
                    setState(() {
                      _selectedColorValue =
                          value;
                    });
                  },
                ),
            ],
          ),

          const SizedBox(
            height: 36,
          ),

          const _EditorSectionLabel(
            text:
                'ICONA',
          ),

          const SizedBox(
            height: 14,
          ),

          GridView.builder(
            shrinkWrap:
                true,
            physics:
                const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  6,
              crossAxisSpacing:
                  10,
              mainAxisSpacing:
                  10,
            ),
            itemCount:
                taskCategoryIconOptions
                    .length,
            itemBuilder:
                (context, index) {
              final option =
                  taskCategoryIconOptions[
                      index];

              return _IconChoice(
                icon:
                    option.icon,
                color:
                    selectedColor,
                selected:
                    option.key ==
                        _selectedIconKey,
                onTap: () {
                  setState(() {
                    _selectedIconKey =
                        option.key;
                  });
                },
              );
            },
          ),
        ],
      ),

      bottomNavigationBar:
          SafeArea(
        minimum:
            const EdgeInsets
                .fromLTRB(
          20,
          8,
          20,
          16,
        ),
        child:
            FilledButton.icon(
          onPressed:
              _saving
                  ? null
                  : _save,
          icon:
              _saving
                  ? const SizedBox(
                      width:
                          18,
                      height:
                          18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth:
                            2,
                      ),
                    )
                  : Icon(
                      _isEditing
                          ? Icons.check
                          : Icons.add,
                    ),
          label:
              Text(
            _isEditing
                ? 'Salva categoria'
                : 'Crea categoria',
          ),
          style:
              FilledButton
                  .styleFrom(
            minimumSize:
                const Size
                    .fromHeight(
              54,
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorSectionLabel
    extends StatelessWidget {
  final String text;

  const _EditorSectionLabel({
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Text(
      text,
      style:
          Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(
                color:
                    Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                fontWeight:
                    FontWeight.w800,
                letterSpacing:
                    1.0,
              ),
    );
  }
}

class _ColorChoice
    extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorChoice({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkResponse(
      onTap:
          onTap,
      radius:
          26,
      child:
          AnimatedContainer(
        duration:
            const Duration(
          milliseconds:
              150,
        ),
        width:
            38,
        height:
            38,
        decoration:
            BoxDecoration(
          color:
              color,
          shape:
              BoxShape.circle,
          border:
              Border.all(
            color:
                selected
                    ? Theme.of(
                        context,
                      )
                        .colorScheme
                        .onSurface
                    : Colors
                        .transparent,
            width:
                2,
          ),
          boxShadow:
              selected
                  ? [
                      BoxShadow(
                        color:
                            color.withValues(
                          alpha:
                              0.28,
                        ),
                        blurRadius:
                            8,
                      ),
                    ]
                  : null,
        ),
        child:
            selected
                ? const Icon(
                    Icons.check,
                    size: 18,
                    color:
                        Colors.white,
                  )
                : null,
      ),
    );
  }
}

class _IconChoice
    extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _IconChoice({
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
          selected
              ? color.withValues(
                  alpha:
                      0.12,
                )
              : Colors
                  .transparent,
      borderRadius:
          BorderRadius.circular(
        12,
      ),
      child:
          InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          12,
        ),
        child:
            Container(
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              12,
            ),
            border:
                Border.all(
              color:
                  selected
                      ? color
                      : colorScheme
                          .outlineVariant
                          .withValues(
                        alpha:
                            0.55,
                      ),
            ),
          ),
          child:
              Icon(
            icon,
            size:
                21,
            color:
                selected
                    ? color
                    : colorScheme
                        .onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
