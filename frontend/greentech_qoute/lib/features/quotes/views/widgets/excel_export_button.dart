import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/quote.dart';
import '../../services/excel_export_service.dart';


/// Drop-in Excel export button.
/// compact = true  → icon only (for AppBar actions)
/// compact = false → outlined button (for detail page)
class ExcelExportButton extends StatefulWidget {
  final Quote quote;
  final bool compact;

  const ExcelExportButton({
    super.key,
    required this.quote,
    this.compact = false,
  });

  @override
  State<ExcelExportButton> createState() => _ExcelExportButtonState();
}


class _ExcelExportButtonState extends State<ExcelExportButton> {
  bool _loading = false;

  Future<void> _export() async {
    setState(() => _loading = true);
    try {
      final file = await ExcelExportService.exportQuote(widget.quote);
      if (!mounted) return;

      // 🌐 Web: download already triggered by the service, just show a snackbar
      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('${widget.quote.refNo}.xlsx downloaded!'),
              ],
            ),
            backgroundColor: const Color(0xFF1A5C2A),
          ),
        );
        return;
      }

      // 📱 Mobile/Desktop: show bottom sheet with Open / Share
      if (file == null) return;

      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF1A5C2A), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Excel export ready',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                file.path.split('/').last,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        OpenFile.open(file.path);
                      },
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Open'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Share.shareXFiles(
                          [XFile(file.path)],
                          subject: 'Quotation ${widget.quote.refNo}',
                        );
                      },
                      icon: const Icon(Icons.share, size: 16),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A5C2A),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );
    }

    if (widget.compact) {
      return IconButton(
        icon: const Icon(Icons.table_view_outlined),
        tooltip: 'Export to Excel',
        onPressed: _export,
      );
    }

    return OutlinedButton.icon(
      onPressed: _export,
      icon: const Icon(Icons.table_view_outlined, size: 18),
      label: const Text('Export Excel'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF1A5C2A),
        side: const BorderSide(color: Color(0xFF1A5C2A)),
      ),
    );
  }
}