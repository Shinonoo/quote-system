import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/quote.dart';
import '../constants/app_constants.dart';

void _slantedPainter(PdfGraphics canvas, PdfPoint size) {
  canvas.setFillColor(PdfColor.fromHex('A2CB8E')); 
  canvas.moveTo(40, 0); 
  canvas.lineTo(size.x, 0);
  canvas.lineTo(size.x, size.y);
  canvas.lineTo(0, size.y); 
  canvas.fillPath();
}

void _checkmarkPainter(PdfGraphics canvas, PdfPoint size) {
  canvas.setStrokeColor(PdfColor.fromHex('4CAF50'));
  canvas.setLineWidth(3);
  canvas.moveTo(0, size.y * 0.5);
  canvas.lineTo(size.x * 0.35, size.y);
  canvas.lineTo(size.x, 0);
  canvas.strokePath();
}

class PdfGenerator {
  PdfGenerator._();

  static final _currency = NumberFormat('#,##0.00', AppConstants.currencyLocale);
  static final _dateFormat = DateFormat('dd-MMM-yy');

  static Future<void> generateAndPrint(Quote quote) async {
    try {
      final pdf = await _buildPdf(quote);
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<int>> generateBytes(Quote quote) async {
    final pdf = await _buildPdf(quote);
    return pdf.save();
  }

  static Future<pw.Document> _buildPdf(Quote quote) async {
    final pdf = pw.Document();
    if (quote.items.isEmpty) throw Exception('Cannot generate PDF for quote with no items');
    
    final grouped = quote.groupedBySection;
    pw.ImageProvider? logoImage;
    try {
      final logoData = await rootBundle.load('assets/images/greentech_logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {}

    final rows = <_PdfRow>[];
    int no = 1;
    int totalQty = 0;
    
    for (final entry in grouped.entries) {
      rows.add(_PdfRow.section(entry.key));
      for (final item in entry.value) {
        bool isRealItem = item.qty > 0;
        if (isRealItem) totalQty += item.qty;
        
        rows.add(_PdfRow.item(
          no: isRealItem ? no++ : 0,
          desc: item.description.isEmpty ? 'No description' : item.description,
          neckSize: item.neckSize.isEmpty ? '-' : item.neckSize,
          qty: item.qty,
          unitPrice: item.unitPrice,
          total: item.total,
        ));
      }
    }

    // ✅ NEW: Check if everything fits on one page
    const itemsPerPage = 14;
    final bool combinedFinalPage = rows.length <= 8; // tweak threshold if needed
    final totalItemsPages = (rows.length / itemsPerPage).ceil().clamp(1, 10);
    final totalPages = combinedFinalPage ? totalItemsPages : totalItemsPages + 1;

    for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
      final isFinalPage = pageIndex == totalPages - 1;
      final isLastItemsPage = pageIndex == totalItemsPages - 1;
      final pageNum = pageIndex + 1;

      pdf.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(24),
            buildBackground: (ctx) => logoImage != null 
              ? pw.FullPage(
                  ignoreMargins: true,
                  child: pw.Center(
                    child: pw.Opacity(
                      opacity: 0.08,
                      child: pw.Image(logoImage, width: 450),
                    )
                  )
                ) 
              : pw.Container(),
          ),
          build: (ctx) {
            if (isFinalPage && !combinedFinalPage) {
              // Separate final page (terms + signatures)
              return _buildFinalPageContent(quote, pageNum, logoImage);
            } else {
              final startIndex = pageIndex * itemsPerPage;
              final endIndex = (startIndex + itemsPerPage).clamp(0, rows.length);
              final pageRows = rows.sublist(startIndex, endIndex);
              
              return _buildItemsPageContent(
                quote, pageRows, isLastItemsPage, pageNum, totalQty, logoImage,
                includeFinalContent: combinedFinalPage && isLastItemsPage, // ✅ NEW
              );
            }
          },
        ),
      );
    }

    return pdf;
  }


  // --- PAGE LAYOUTS ---

static pw.Widget _buildItemsPageContent(
  Quote quote, 
  List<_PdfRow> rows, 
  bool isLastItemsPage, 
  int pageNum, 
  int totalQty, 
  pw.ImageProvider? logoImage,
  {bool includeFinalContent = false} // ✅ NEW parameter
) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children:[
      if (pageNum == 1) ...[
        _buildHeader(logoImage),
        pw.SizedBox(height: 8),
        _buildContactInfo(),
        pw.SizedBox(height: 12),
        _buildInfoTable(quote),
        pw.SizedBox(height: 8),
      ],
      _buildItemsTable(quote, rows, isLastItemsPage, totalQty),
      if (isLastItemsPage) ...[
        _buildNotesAndTotals(quote),
        pw.SizedBox(height: 6),
        _buildTermsPart1(),
        if (includeFinalContent) ...[  // ✅ NEW: Add terms part 2 + signatures
          pw.SizedBox(height: 12),
          _buildTermsPart2(),
          pw.SizedBox(height: 16),
          _buildSignatures(),
        ],
      ],
      pw.Spacer(),
      _buildPageFooter(pageNum),
    ],
  );
}

  static pw.Widget _buildFinalPageContent(Quote quote, int pageNum, pw.ImageProvider? logoImage) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children:[
        _buildHeader(logoImage),
        pw.SizedBox(height: 8),
        _buildContactInfo(),
        pw.SizedBox(height: 24),
        _buildTermsPart2(),
        pw.SizedBox(height: 16),
        _buildSignatures(),
        pw.Spacer(),
        _buildPageFooter(pageNum),
      ],
    );
  }

  // --- COMPONENTS ---

  static pw.Widget _buildHeader(pw.ImageProvider? logoImage) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children:[
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children:[
            logoImage != null
                ? pw.Image(logoImage, width: 65, height: 65)
                : pw.Container(width: 65, height: 65),
            pw.SizedBox(width: 8),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children:[
                pw.Text('GREENTECH', style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 45),
                  child: pw.Text('INDL INC', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                )
              ],
            ),
          ],
        ),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: pw.Container(
            height: 65,
            child: pw.Stack(
              children:[
                pw.Positioned.fill(
                  child: pw.CustomPaint(painter: _slantedPainter), 
                ),
                pw.Center(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 30, right: 10),
                    child: pw.Text(
                      '" Your partner in AIR TERMINALS, INSULATIONS,\nHVAC Products & MERV FILTERS "',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildContactInfo() {
    return pw.RichText(
      textAlign: pw.TextAlign.center,
      text: pw.TextSpan(
        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
        children:[
          pw.TextSpan(text: 'Address: '),
          pw.TextSpan(text: '17 Pescadores Pag-asa 4309 Macalelon Quezon Philippines', style: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold)),
          pw.TextSpan(text: '  |  Telephone : '),
          pw.TextSpan(text: '(028) 736-8876', style: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold)),
          pw.TextSpan(text: '  |  Tele-Fax: '),
          pw.TextSpan(text: '(028) 828-2496', style: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold)),
          pw.TextSpan(text: '\nWireless: '),
          pw.TextSpan(text: '(028) 782-6117 / 985-8441', style: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold)),
          pw.TextSpan(text: '  |  E-mail: '),
          pw.TextSpan(text: 'sales@greentechindl.com', style: pw.TextStyle(color: PdfColor.fromHex('1976D2'))),
          pw.TextSpan(text: '  |  Website: '),
          pw.TextSpan(text: 'http://www.greentechindl.com', style: pw.TextStyle(color: PdfColor.fromHex('1976D2'))),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoTable(Quote quote) {
    final dateStr = _dateFormat.format(quote.date);
    final bg = PdfColor.fromHex('F0F0F0');

    pw.Widget c(pw.Widget child, {bool r = false, bool b = false, PdfColor? bgColor}) {
      return pw.Container(
        decoration: pw.BoxDecoration(
          color: bgColor,
          border: pw.Border(
            right: r ? const pw.BorderSide() : pw.BorderSide.none,
            bottom: b ? const pw.BorderSide() : pw.BorderSide.none,
          ),
        ),
        child: child,
      );
    }

    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children:[
          pw.Row(children:[
            pw.Expanded(flex: 55, child: c(_headerCell('COMPANY'), r: true, b: true, bgColor: bg)),
            pw.Expanded(flex: 20, child: c(_headerCell('DATE'), r: true, b: true, bgColor: bg)),
            pw.Expanded(flex: 25, child: c(_headerCell('REFERENCE NO.'), b: true, bgColor: bg)),
          ]),
          pw.Row(children:[
            pw.Expanded(flex: 55, child: c(pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children:[
              pw.Text(quote.company.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.Text(quote.companyLocation.toUpperCase(), style: const pw.TextStyle(fontSize: 9)),
            ])), r: true, b: true)),
            pw.Expanded(flex: 20, child: c(pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Center(child: pw.Text(dateStr, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)))), r: true, b: true)),
            pw.Expanded(flex: 25, child: c(pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Center(child: pw.Text(quote.refNo, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColor.fromHex('1976D2'))))), b: true)),
          ]),
          pw.Row(children:[
            pw.Expanded(flex: 55, child: c(_headerCell('ATTENTION'), r: true, b: true, bgColor: bg)),
            pw.Expanded(flex: 45, child: c(_headerCell('PAYMENT TERMS'), b: true, bgColor: bg)),
          ]),
          pw.Row(children:[
            pw.Expanded(flex: 55, child: c(pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children:[
              pw.Text(quote.attention.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text(quote.attentionTitle.toUpperCase(), style: const pw.TextStyle(fontSize: 9)),
            ])), r: true, b: true)),
            pw.Expanded(flex: 45, child: c(pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Center(child: pw.Text(quote.paymentTerms.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColor.fromHex('D32F2F'))))), b: true)),
          ]),
          pw.Row(children:[
            pw.Expanded(flex: 55, child: c(_headerCell('PROJECT & LOCATION'), r: true, b: true, bgColor: bg)),
            pw.Expanded(flex: 45, child: c(_headerCell('LEADTIME'), b: true, bgColor: bg)),
          ]),
          pw.Row(children:[
            pw.Expanded(flex: 55, child: c(pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children:[
              pw.Text(quote.projectLocation.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text(quote.supplyDescription.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ])), r: true)),
            pw.Expanded(flex: 45, child: c(pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Center(child: pw.Text(quote.leadtime.toUpperCase(), textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColor.fromHex('1976D2'))))))),
          ]),
        ],
      )
    );
  }

  static pw.Widget _buildItemsTable(Quote quote, List<_PdfRow> rows, bool isLastPage, int totalQty) {
    return pw.Table(
      border: pw.TableBorder.all(width: 1),
      columnWidths: {
        0: const pw.FixedColumnWidth(35),
        1: const pw.FixedColumnWidth(232),
        2: const pw.FixedColumnWidth(85),
        3: const pw.FixedColumnWidth(50),
        4: const pw.FixedColumnWidth(70),
        5: const pw.FixedColumnWidth(75),
      },
      children:[
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('F0F0F0')),
          children:[
            _itemHeaderCell('No.'),
            _itemHeaderCell('Description'),
            _itemHeaderCell('Size (mm)\nL x W'),
            _itemHeaderCell('Qty'),
            _itemHeaderCell('Unit price'),
            _itemHeaderCell('TOTAL'),
          ],
        ),
        ...rows.map((row) {
          if (row.isSectionHeader) {
            return pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('F0F0F0')),
              children:[
                _cell(pw.Container(), rightBorder: false),
                _cell(pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Center(child: pw.Text(row.section?.toUpperCase() ?? '', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)))), rightBorder: false),
                _cell(pw.Container(), rightBorder: false),
                _cell(pw.Container(), rightBorder: false),
                _cell(pw.Container(), rightBorder: false),
                _cell(pw.Container(), rightBorder: false),
              ],
            );
          } else if (row.isSubHeader) {
            return pw.TableRow(
              children:[
                _cell(pw.Container(), rightBorder: true),
                _cell(pw.Padding(padding: const pw.EdgeInsets.all(4), child: _buildSubHeaderText(row.desc ?? '')), rightBorder: true),
                _cell(pw.Container(), rightBorder: true),
                _cell(pw.Container(), rightBorder: true),
                _cell(pw.Container(), rightBorder: true),
                _cell(pw.Container(), rightBorder: false),
              ],
            );
          } else {
            return pw.TableRow(
              children:[
                _cell(_itemCell(row.no != null && row.no! > 0 ? '${row.no}.0' : '-', align: pw.TextAlign.center), rightBorder: true),
                _cell(pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2), child: _buildItemDescription(row.desc ?? 'No description')), rightBorder: true),
                _cell(_itemCell(row.neckSize ?? '', align: pw.TextAlign.center, isBold: true), rightBorder: true),
                _cell(_itemCell('${row.qty}  pc/s', align: pw.TextAlign.center, isBold: true), rightBorder: true),
                _cell(_itemCell(_currency.format(row.unitPrice), align: pw.TextAlign.right), rightBorder: true),
                _cell(_itemCell(_currency.format(row.total), align: pw.TextAlign.right), rightBorder: false),
              ],
            );
          }
        }),
        if (isLastPage)
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.white),
            children:[
              _cell(pw.Container(), rightBorder: false),
              _cell(pw.Container(), rightBorder: false),
              _cell(
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text('TOTAL QTY', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColor.fromHex('D32F2F'))),
                  ),
                ),
                rightBorder: true,
              ),
              _cell(
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Center(child: pw.Text('$totalQty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColor.fromHex('D32F2F')))),
                ),
                rightBorder: true,
              ),
              _cell(pw.Container(), rightBorder: true),
              _cell(pw.Container(), rightBorder: false),
            ],
          ),
      ],
    );
  }

  // Uses pw.Table to safely map the columns without crashing the Layout Engine!
  static pw.Widget _buildNotesAndTotals(Quote quote) {
    return pw.Table(
      border: pw.TableBorder(
        left: const pw.BorderSide(),
        right: const pw.BorderSide(),
        bottom: const pw.BorderSide(),
      ),
      columnWidths: {
        0: const pw.FixedColumnWidth(402), // Match Cols 0+1+2+3
        1: const pw.FixedColumnWidth(70),  // Match Col 4
        2: const pw.FixedColumnWidth(75),  // Match Col 5
      },
      children: [
        pw.TableRow(
          children:[
            // Notes Section
            pw.Container(
              decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide())),
              padding: const pw.EdgeInsets.all(4),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children:[
                  pw.Container(
                    color: PdfColor.fromHex('1976D2'),
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: pw.Text('NOTES', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text('1. G.I - Galvanized iron; AL - Aluminum', style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('1976D2'))),
                  pw.Text('2. STANDARD ENAMEL PAINT (WHITE) unless specified (For Air grilles only).', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('1976D2'))),
                  pw.Text('3. For approval of sample &shop drawing (if necessary).', style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('1976D2'))),
                  pw.Text('4. All works NOT mentioned in the proposal are Excluded.', style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('1976D2'))),
                ]
              )
            ),
            // Subtotal 1 Label
            pw.Container(
              decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(), bottom: pw.BorderSide())),
              padding: const pw.EdgeInsets.all(4),
              child: pw.Align(
                alignment: pw.Alignment.topCenter,
                child: pw.Text('Subtotal 1', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              )
            ),
            // Subtotal 1 Value
            pw.Container(
              decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide())),
              padding: const pw.EdgeInsets.all(4),
              child: pw.Align(
                alignment: pw.Alignment.topRight,
                child: pw.Text(_currency.format(quote.total), style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)
              )
            ),
          ]
        ),
        pw.TableRow(
          children:[
            // Empty Cell under Notes
            pw.Container(
              decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide())),
            ),
            // Total Label
            pw.Container(
              decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide())),
              padding: const pw.EdgeInsets.all(4),
              child: pw.Center(child: pw.Text('Total (Vat inc)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)))
            ),
            // Total Value
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(_currency.format(quote.total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11), textAlign: pw.TextAlign.right)
              )
            ),
          ]
        )
      ]
    );
  }

  // General Terms
  static pw.Widget _buildTermsPart1() {
    final terms =[
      'VALIDITY: (15) FIFTEEN DAYS FROM THE DATE OF QUOTATION',
      'Price is Supply only. Other works like Hauling, Rigging, Positioning of equipment and Installations are excluded.',
      'For Purchase Orders above PHP 50,000, delivery is free within Metro Manila. Purchase Orders below PHP 50,000 are for warehouse pickup.',
      'Delivery within Metro Manila only; Outside Metro Manila will require additional cost.',
      'Delivery is unloading only, exclusive of hauling and any other works.',
    ];
    return _renderTermsList(terms);
  }

  // Warranty and Cancellation
  static pw.Widget _buildTermsPart2() {
    final terms =[
      'NO WARRANTY ON SUPPLIED MATERIAL. Kindly check item in receiving delivered items.',
      'NO WARRANTY ON PAINT. Kindly check item in receiving delivered items.',
      'Upon cancellation of order of items/equipments, the buyer shall pay 25% cancellation fee and 25% re-stocking fee in the total contract price.',
      'Additional measurements, materials and equipments will require additional cost.',
      'Change of measurements, materials and equipments will require additional cost.',
    ];
    return _renderTermsList(terms);
  }

  static pw.Widget _renderTermsList(List<String> terms) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: terms.map((term) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children:[
            pw.Text('• ', style: pw.TextStyle(fontSize: 8, color: term.contains('VALIDITY') ? PdfColor.fromHex('1976D2') : PdfColors.black)),
            pw.Expanded(
              child: pw.Text(
                term,
                style: pw.TextStyle(
                  fontSize: 8,
                  color: term.contains('VALIDITY') ? PdfColor.fromHex('1976D2') : PdfColors.black,
                  fontWeight: term.contains('VALIDITY') || term.contains('For Purchase') || term.contains('Delivery within')
                      ? pw.FontWeight.bold 
                      : pw.FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  static pw.Widget _buildSignatures() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children:[
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children:[
              pw.Text('Prepared by:', style: const pw.TextStyle(fontSize: 9)),
              pw.SizedBox(height: 16),
              pw.Text('Engr. Roy Benitez', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text('Senior Sales Engineer', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Mobile: +632 933 869 7479', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Email: rcbenitez@greentechindl.com', style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children:[
              pw.SizedBox(height: 26),
              pw.Text('Ms. Issah G. Doria', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text('Sales Manager', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Mobile: +632 933 812 4607', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Email: cgd@greentechindl.com', style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children:[
              pw.Text('Accepted and Conformed by:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
              pw.SizedBox(height: 4),
              pw.Stack(
                alignment: pw.Alignment.bottomRight,
                children:[
                  pw.Container(
                    width: 170, height: 35,
                    alignment: pw.Alignment.bottomCenter,
                    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1))),
                  ),
                  pw.Positioned(
                    right: 15, bottom: 5,
                    child: pw.Container(
                      width: 20, height: 20,
                      child: pw.CustomPaint(
                        size: const PdfPoint(20, 20),
                        painter: _checkmarkPainter 
                      ),
                    )
                  )
                ]
              ),
              pw.SizedBox(height: 4),
              pw.Text("Clients' Signature over printed name", style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPageFooter(int pageNum) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children:[
        pw.Text(
          '"Thank you for giving us the opportunity to quote on your requirements."',
          style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColor.fromHex('1976D2')),
        ),
        pw.Text('pg.$pageNum', style: const pw.TextStyle(fontSize: 8)),
      ],
    );
  }

  // --- Utility Formatting ---

  static pw.Widget _cell(pw.Widget child, {bool rightBorder = true}) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          right: rightBorder ? const pw.BorderSide(width: 1) : pw.BorderSide.none,
        ),
      ),
      child: child,
    );
  }

  static pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 8)),
    );
  }

  static pw.Widget _itemHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Center(
        child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.center),
      ),
    );
  }

  static pw.Widget _itemCell(String text, {bool isBold = false, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildSubHeaderText(String text) {
    if (text.contains(':') && !text.startsWith('GI')) {
      final parts = text.split(':');
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children:[
          pw.SizedBox(
            width: 75,
            child: pw.Text('${parts[0]}:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Text(parts.sublist(1).join(':').trim(), style: const pw.TextStyle(fontSize: 8)),
          ),
        ],
      );
    } else if (text.startsWith('GI')) {
      return pw.Text(text, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold));
    }
    return pw.Text(text, style: const pw.TextStyle(fontSize: 9));
  }

  static pw.Widget _buildItemDescription(String desc) {
    if (desc.startsWith('-') && desc.length > 2) {
      final parts = desc.split(' ');
      final lastWord = parts.last.trim();
      
      if (lastWord == lastWord.toUpperCase() && lastWord.length <= 4) {
        final firstPart = desc.substring(0, desc.lastIndexOf(lastWord)).trim();
        return pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children:[
            pw.Text(firstPart, style: const pw.TextStyle(fontSize: 9)),
            pw.Text(lastWord, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('1A237E'))),
          ]
        );
      }
    }
    return pw.Text(desc, style: const pw.TextStyle(fontSize: 9));
  }
}

class _PdfRow {
  final bool isSectionHeader;
  final String? section;
  final int? no;
  final String? desc;
  final String? neckSize;
  final int? qty;
  final double? unitPrice;
  final double? total;

  bool get isSubHeader => !isSectionHeader && (qty == null || qty == 0);

  const _PdfRow._({
    this.isSectionHeader = false, this.section, this.no, this.desc, this.neckSize, this.qty, this.unitPrice, this.total,
  });

  factory _PdfRow.section(String section) => _PdfRow._(isSectionHeader: true, section: section);

  factory _PdfRow.item({required int? no, required String desc, required String? neckSize, required int qty, required double unitPrice, required double total}) =>
      _PdfRow._(no: no, desc: desc, neckSize: neckSize, qty: qty, unitPrice: unitPrice, total: total);
}