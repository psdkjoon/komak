import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:komak/core/models/flashcard.dart';
import 'package:komak/core/services/app_controller.dart';
import 'package:komak/core/theme/app_spacing.dart';
import 'package:komak/core/widgets/app_scope.dart';
import 'package:komak/core/widgets/common_widgets.dart';
import 'package:komak/core/widgets/sliver_content.dart';

class CardEditorScreen extends StatefulWidget {
  const CardEditorScreen({super.key, required this.deckId, this.existingCard});

  final String deckId;
  final Flashcard? existingCard;

  @override
  State<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends State<CardEditorScreen> {
  late final TextEditingController _frontController;
  late final TextEditingController _backController;
  late final TextEditingController _orderController;
  late final TextEditingController _groupController;
  final FocusNode _frontFocus = FocusNode();

  bool get _isEditing => widget.existingCard != null;

  @override
  void initState() {
    super.initState();
    _frontController =
        TextEditingController(text: widget.existingCard?.front ?? '');
    _backController =
        TextEditingController(text: widget.existingCard?.back ?? '');
    _orderController = TextEditingController(
        text: widget.existingCard?.orderIndex?.toString() ?? '',);
    _groupController =
        TextEditingController(text: widget.existingCard?.groupId ?? '');
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _orderController.dispose();
    _groupController.dispose();
    _frontFocus.dispose();
    super.dispose();
  }

  Future<void> _save({bool addAnother = false}) async {
    if (_frontController.text.trim().isEmpty ||
        _backController.text.trim().isEmpty) {
      return;
    }
    final AppController controller = AppScope.of(context);

    final Flashcard card = Flashcard(
      id: widget.existingCard?.id,
      front: _frontController.text.trim(),
      back: _backController.text.trim(),
      orderIndex: int.tryParse(_orderController.text.trim()),
      groupId: _groupController.text.trim().isEmpty
          ? null
          : _groupController.text.trim(),
    );

    if (_isEditing) {
      await controller.updateCard(widget.deckId, card);
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    await controller.addCardsToDeck(widget.deckId, <Flashcard>[card]);
    if (!mounted) return;
    if (addAnother) {
      _frontController.clear();
      _backController.clear();
      _orderController.clear();
      _groupController.clear();
      _frontFocus.requestFocus();
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Card added')));
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit card' : 'New card')),
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverContent(
              maxWidth: AppLayout.readableMaxWidth,
              sliver: SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(<Widget>[
                    SectionCard(
                      child: Column(
                        children: <Widget>[
                          TextField(
                            controller: _frontController,
                            focusNode: _frontFocus,
                            autofocus: !_isEditing,
                            maxLines: 3,
                            minLines: 1,
                            decoration: const InputDecoration(
                                labelText: 'Front (question)',),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            controller: _backController,
                            maxLines: 3,
                            minLines: 1,
                            decoration: const InputDecoration(
                                labelText: 'Back (answer)',),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SectionCard(
                      title: 'Optional',
                      child: Column(
                        children: <Widget>[
                          TextField(
                            controller: _orderController,
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Order position',
                              helperText:
                                  'Fill this in on 3+ cards to unlock the Correct Order type.',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            controller: _groupController,
                            decoration: const InputDecoration(
                              labelText: 'Group label',
                              helperText:
                                  'Shared across cards, unlocks the Odd One Out type.',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: _save,
                      icon: Icon(
                          _isEditing ? Icons.check_rounded : Icons.add_rounded,),
                      label: Text(_isEditing ? 'Save changes' : 'Add card'),
                    ),
                    if (!_isEditing) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      OutlinedButton.icon(
                        onPressed: () => _save(addAnother: true),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        label: const Text('Add and add another'),
                      ),
                    ],
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
