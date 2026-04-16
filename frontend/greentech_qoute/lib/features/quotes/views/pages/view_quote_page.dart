import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../services/pdf_generator.dart';
import '../../models/quote.dart';
import '../../models/quote_item.dart';
import '../../repositories/quote_repository.dart';
import '../widgets/excel_export_button.dart';
import '../widgets/item_list_tile.dart';
import '../../../../shared/widgets/section_header.dart';
import 'add_quote/add_quote_page.dart';


class ViewQuotePage extends StatefulWidget {
  final Quote quote;

  const ViewQuotePage({super.key, required this.quote});

  @override
  State<ViewQuotePage> createState() => _ViewQuotePageState();
}


class _ViewQuotePageState extends State<ViewQuotePage> {
  late Quote _quote;
  final _repository = QuoteRepository();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _quote = widget.quote;

    final isLocalQuote = int.tryParse(_quote.id) == null || _quote.id.length > 10;

    if (_repository.useApi && _quote.items.isEmpty && !isLocalQuote) {
      _loadQuoteDetails();
    }
  }

  Future<void> _loadQuoteDetails() async {
    setState(() => _isLoading = true);
    try {
      final apiQuote = await _repository.getByQuoteNoFromApi(_quote.refNo);
      if (apiQuote != null) {
        setState(() {
          _quote = _repository.apiQuoteToLocalQuote(apiQuote);
        });
      }
    } catch (e) {
      // Ignore error, show quote without items
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editQuote() async {
    final result = await Navigator.push<Quote>(
      context,
      MaterialPageRoute(builder: (_) => AddQuotePage(editQuote: _quote)),
    );
    if (result != null) {
      await _repository.saveLocal(result);
      setState(() => _quote = result);
      if (mounted) {
        Navigator.pop(context, result);
      }
    }
  }

  Future<void> _changeStatus(QuoteStatus status) async {
    setState(() => _isLoading = true);
    try {
      final success = await _repository.updateStatus(_quote.id, _quote.refNo, status);
      if (success) {
        setState(() => _quote.status = status);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status updated to ${_quote.statusLabel}')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update status')),
          );
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _printPdf() async {
    try {
      await PdfGenerator.generateAndPrint(_quote);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sharePdf() async {
    try {
      await PdfGenerator.generateBytes(_quote);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF ready to share')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ❌ _exportExcel() REMOVED — ExcelExportButton handles itself

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_quote.refNo),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
          // ✅ ExcelExportButton used directly as a widget (compact = icon only)
          ExcelExportButton(quote: _quote, compact: true),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _repository.useApi ? _loadQuoteDetails : null,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editQuote();
                  break;
                case 'pdf':
                  _printPdf();
                  break;
                case 'share':
                  _sharePdf();
                  break;
                // ❌ 'excel' case REMOVED
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 20),
                    SizedBox(width: 8),
                    Text('View PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20),
                    SizedBox(width: 8),
                    Text('Share'),
                  ],
                ),
              ),
              // ❌ Excel PopupMenuItem REMOVED
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Quote Information',
              icon: Icons.receipt_long,
              child: Column(
                children: [
                  _buildInfoRow('Reference No.', _quote.refNo),
                  _buildInfoRow(
                    'Date',
                    DateFormat('MMM dd, yyyy').format(_quote.date),
                  ),
                  _buildInfoRow(
                    'Created',
                    DateFormat('MMM dd, yyyy - h:mm a').format(_quote.createdAt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Client Information',
              icon: Icons.business,
              child: Column(
                children: [
                  _buildInfoRow('Company', _quote.company, isBold: true),
                  _buildInfoRow('Location', _quote.companyLocation),
                  _buildInfoRow('Attention', _quote.attention, isBold: true),
                  _buildInfoRow('Title', _quote.attentionTitle),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Project Information',
              icon: Icons.construction,
              child: Column(
                children: [
                  _buildInfoRow('Project', _quote.projectLocation, isBold: true),
                  _buildInfoRow('Supply', _quote.supplyDescription),
                  _buildInfoRow('Payment Terms', _quote.paymentTerms),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Items (${_quote.itemCount})',
              icon: Icons.inventory_2,
              child: _quote.items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No items found. Tap refresh to load.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ..._buildGroupedItems(),
                        const Divider(height: 32),
                        _buildTotalSection(),
                      ],
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _printPdf,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('PDF'),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;

    switch (_quote.status) {
      case QuoteStatus.approved:
        statusColor = AppTheme.approvedColor;
        statusIcon = Icons.check_circle;
        break;
      case QuoteStatus.rejected:
        statusColor = AppTheme.rejectedColor;
        statusIcon = Icons.cancel;
        break;
      case QuoteStatus.expired:
        statusColor = AppTheme.expiredColor;
        statusIcon = Icons.timer_off;
        break;
      case QuoteStatus.pending:
        statusColor = AppTheme.pendingColor;
        statusIcon = Icons.pending;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(statusIcon, color: statusColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: ${_quote.statusLabel}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap to change status',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<QuoteStatus>(
            icon: const Icon(Icons.more_vert),
            onSelected: _changeStatus,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: QuoteStatus.pending,
                child: Text('Pending'),
              ),
              const PopupMenuItem(
                value: QuoteStatus.approved,
                child: Text('Approved'),
              ),
              const PopupMenuItem(
                value: QuoteStatus.rejected,
                child: Text('Rejected'),
              ),
              const PopupMenuItem(
                value: QuoteStatus.expired,
                child: Text('Expired'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.secondaryText,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedItems() {
    final grouped = <String, List<QuoteItem>>{};
    for (final item in _quote.items) {
      grouped.putIfAbsent(item.section, () => []).add(item);
    }

    final widgets = <Widget>[];
    int globalIndex = 0;

    for (final entry in grouped.entries) {
      final sectionItems = entry.value;
      final sectionTotal =
          sectionItems.fold<double>(0.0, (s, i) => s + i.total);

      widgets.add(
        ItemSectionHeader(
          section: entry.key,
          sectionTotal: sectionTotal,
          itemCount: sectionItems.length,
        ),
      );
      widgets.add(const SizedBox(height: 8));

      for (var i = 0; i < sectionItems.length; i++) {
        widgets.add(
          ItemListTile(
            item: sectionItems[i],
            index: globalIndex++,
            showSection: false,
            onRemove: null,
          ),
        );
      }
      widgets.add(const SizedBox(height: 16));
    }

    return widgets;
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Items',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                '${_quote.itemCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Quantity',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                '${_quote.totalQty} pc/s',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL AMOUNT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _quote.total.asCurrencyWithSymbol,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}