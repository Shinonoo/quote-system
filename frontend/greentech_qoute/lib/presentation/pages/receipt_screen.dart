import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:printing/printing.dart';
import '../../data/datasources/remote_data_source.dart';  // Fixed path
import '../../core/errors/api_exception.dart';
import '../../utils/error_handler.dart';
import '../../utils/quote_pdf_generator.dart';

class ReceiptScreen extends StatefulWidget {
  final dynamic quoteNo;

  const ReceiptScreen({Key? key, required this.quoteNo}) : super(key: key);

  @override
  _ReceiptScreenState createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final ApiClient _apiClient = ApiClient();
  final Color primaryGreen = const Color(0xFF2D5A3D); 

  Map<String, dynamic>? _quotationData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchReceiptDetails();
  }

  Future<void> _fetchReceiptDetails() async {
    try {
      final response = await _apiClient.dio.get('/quotes/${widget.quoteNo}');
      if (mounted) {
        setState(() {
          _quotationData = response.data['data'] ?? response.data;
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      final error = e.error is ApiException
          ? e.error as ApiException
          : ApiException('Failed to load receipt.');
      _handleStateError(error.message, error);
    } catch (e) {
      _handleStateError('Unexpected error loading receipt.', ApiException('Unexpected error.'));
    }
  }

  void _handleStateError(String message, Exception error) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = message;
      });
      handleError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quotation ${widget.quoteNo}', 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade50,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:[
            CircularProgressIndicator(color: primaryGreen, strokeWidth: 3),
            const SizedBox(height: 16),
            const Text('Generating Document...', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    if (_errorMessage != null || _quotationData == null) {
      return _buildErrorState();
    }

    return PdfPreview(
      build: (format) => QuotePdfGenerator.generate(format, _quotationData!),
      allowSharing: true,
      allowPrinting: true,
      canChangePageFormat: false,
      pdfFileName: 'GreenTech_Quote_${widget.quoteNo}.pdf',
      loadingWidget: CircularProgressIndicator(color: primaryGreen),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.description_outlined, size: 64, color: Colors.red.shade300),
            ),
            const SizedBox(height: 24),
            const Text('Failed to load document', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unexpected error occurred.', 
              style: TextStyle(color: Colors.grey.shade600, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _fetchReceiptDetails();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen, 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
