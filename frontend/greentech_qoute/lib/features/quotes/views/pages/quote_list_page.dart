import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../services/pdf_generator.dart';
import '../../models/quote.dart';
import '../../repositories/quote_repository.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/section_header.dart';  // create this file
import '../widgets/quote_list_item.dart';
import 'add_quote/add_quote_page.dart';
import 'view_quote_page.dart';

class QuoteListPage extends StatefulWidget {
  const QuoteListPage({super.key});

  @override
  State<QuoteListPage> createState() => _QuoteListPageState();
}

class _QuoteListPageState extends State<QuoteListPage> {
  final _repository = QuoteRepository();
  final _searchController = TextEditingController();
  List<Quote> _allQuotes = []; // All quotes (both API and local)
  List<Quote> _filteredQuotes = [];
  QuoteStatus? _selectedFilter;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<Quote> quotes;
      
      if (_repository.useApi) {
        final apiQuotes = await _repository.getAllFromApi();
        quotes = apiQuotes.map((q) => _repository.apiQuoteToLocalQuote(q)).toList();
      } else {
        quotes = await _repository.getAllLocal();
      }

      setState(() {
        _allQuotes = quotes;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    var filtered = List<Quote>.from(_allQuotes);

    // Apply status filter
    if (_selectedFilter != null) {
      filtered = filtered.where((q) => q.status == _selectedFilter).toList();
    }

    // Apply search filter
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((q) {
        return q.refNo.toLowerCase().contains(query) ||
            q.company.toLowerCase().contains(query) ||
            q.projectLocation.toLowerCase().contains(query);
      }).toList();
    }

    setState(() => _filteredQuotes = filtered);
  }

  void _onSearchChanged(String value) => _applyFilter();

  void _onFilterChanged(QuoteStatus? status) {
    setState(() {
      _selectedFilter = status;
      _applyFilter();
    });
  }

  Future<void> _navigateToAddQuote() async {
    final result = await Navigator.push<Quote>(
      context,
      MaterialPageRoute(builder: (_) => const AddQuotePage()),
    );
    if (result != null) {
      // Quote is already saved in AddQuotePage
      // Just refresh the list
      _loadQuotes();
    }
  }

  Future<void> _navigateToViewQuote(Quote quote) async {
    final result = await Navigator.push<Quote>(
      context,
      MaterialPageRoute(builder: (_) => ViewQuotePage(quote: quote)),
    );
    if (result != null && !_repository.useApi) {
      await _repository.saveLocal(result);
      _loadQuotes();
    }
  }

  Future<void> _generatePdf(Quote quote) async {
    try {
      await PdfGenerator.generateAndPrint(quote);
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

  Future<void> _deleteQuote(Quote quote) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quote'),
        content: Text('Are you sure you want to delete ${quote.refNo}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!_repository.useApi) {
        await _repository.deleteLocal(quote.id);
      }
      _loadQuotes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quote deleted')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          // API/Local indicator
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _repository.useApi ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _repository.useApi ? 'ONLINE' : 'LOCAL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _repository.useApi ? Colors.green : Colors.orange,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuotes,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SearchField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  hint: 'Search quotes...',
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', null),
                      _buildFilterChip('Pending', QuoteStatus.pending),
                      _buildFilterChip('Approved', QuoteStatus.approved),
                      _buildFilterChip('Rejected', QuoteStatus.rejected),
                      _buildFilterChip('Expired', QuoteStatus.expired),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Error Message
          if (_error != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadQuotes,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),

          // Stats Section
          if (_filteredQuotes.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStat(
                      '${_filteredQuotes.length}',
                      'Total Quotes',
                      Icons.description_outlined,
                    ),
                  ),
                  Expanded(
                    child: _buildStat(
                      '${_filteredQuotes.where((q) => q.status == QuoteStatus.pending).length}',
                      'Pending',
                      Icons.pending_outlined,
                    ),
                  ),
                  Expanded(
                    child: _buildStat(
                      '${_filteredQuotes.where((q) => q.status == QuoteStatus.approved).length}',
                      'Approved',
                      Icons.check_circle_outline,
                    ),
                  ),
                ],
              ),
            ),

          // Quote List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredQuotes.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadQuotes,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 80),
                          itemCount: _filteredQuotes.length,
                          itemBuilder: (context, index) {
                            final quote = _filteredQuotes[index];
                            return Dismissible(
                              key: Key(quote.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              confirmDismiss: (_) async {
                                await _deleteQuote(quote);
                                return false;
                              },
                              child: QuoteListItem(
                                quote: quote,
                                onTap: () => _navigateToViewQuote(quote),
                                onPdfTap: () => _generatePdf(quote),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddQuote,
        icon: const Icon(Icons.add),
        label: const Text('New Quote'),
      ),
    );
  }

  Widget _buildFilterChip(String label, QuoteStatus? status) {
    final isSelected = _selectedFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _onFilterChanged(isSelected ? null : status),
        selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryGreen : AppTheme.secondaryText,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.secondaryText),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.secondaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchController.text.isNotEmpty ||
        _selectedFilter != null;
    return EmptyState(
      message: isSearching ? 'No matching quotes' : 'No quotes yet',
      subMessage: isSearching
          ? 'Try different search terms or filters'
          : 'Tap + to create your first quote',
      icon: isSearching ? Icons.search_off : Icons.folder_open,
      action: isSearching
          ? TextButton(
              onPressed: () {
                _searchController.clear();
                _onFilterChanged(null);
              },
              child: const Text('Clear Filters'),
            )
          : ElevatedButton.icon(
              onPressed: _navigateToAddQuote,
              icon: const Icon(Icons.add),
              label: const Text('Create Quote'),
            ),
    );
  }
}
