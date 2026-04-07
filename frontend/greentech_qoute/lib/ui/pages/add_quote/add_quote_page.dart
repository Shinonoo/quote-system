import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/pdf_generator.dart';
import '../../../data/models/quote.dart';
import 'add_quote_controller.dart';
import 'sections/quote_info_section.dart';
import 'sections/client_info_section.dart';
import 'sections/project_info_section.dart';
import 'sections/add_items_section.dart';
import 'sections/items_preview_section.dart';

class AddQuotePage extends StatefulWidget {
  final Quote? editQuote;

  const AddQuotePage({super.key, this.editQuote});

  @override
  State<AddQuotePage> createState() => _AddQuotePageState();
}

class _AddQuotePageState extends State<AddQuotePage> {
  late final AddQuoteController _controller;
  late final VoidCallback _controllerListener;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _controller = AddQuoteController(
      editQuote: widget.editQuote,
      onError: _showError,
      onSuccess: _showSuccess,
    );

    _controllerListener = () {
      if (mounted) setState(() {});
    };

    _controller.addListener(_controllerListener);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 14)),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: message.length > 60
            ? SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              )
            : null,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _previewPdf() async {
    if (_controller.items.isEmpty) {
      _showError('Add items to preview PDF');
      return;
    }
    try {
      await PdfGenerator.generateAndPrint(_controller.buildQuote());
    } catch (e) {
      _showError('Failed to generate PDF: $e');
    }
  }

  Future<void> _saveQuote() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      _showError('Please fill in all required fields');
      return;
    }

    final quote = await _controller.saveQuote();

    if (!mounted) return;
    if (quote != null) Navigator.pop(context, quote);
  }

  @override
  void dispose() {
    _controller.removeListener(_controllerListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editQuote != null ? 'Edit Quote' : 'New Quote'),
        actions: [
          if (_controller.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _previewPdf,
              tooltip: 'Preview PDF',
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _controller.isSaving ? null : _saveQuote,
            tooltip: 'Save Quote',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              QuoteInfoSection(controller: _controller),
              const SizedBox(height: 16),
              ClientInfoSection(controller: _controller),
              const SizedBox(height: 16),
              ProjectInfoSection(controller: _controller),
              const SizedBox(height: 16),
              AddItemsSection(controller: _controller),
              const SizedBox(height: 16),
              if (_controller.items.isNotEmpty) ...[
                ItemsPreviewSection(controller: _controller),
                const SizedBox(height: 24),
              ],
              _buildSaveButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _controller.isSaving ? null : _saveQuote,
        icon: _controller.isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.save),
        label: Text(
          _controller.isSaving
              ? 'Saving...'
              : (widget.editQuote != null ? 'Update Quote' : 'Save Quote'),
        ),
      ),
    );
  }
}