import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart'; // ← was '../constants/...' (missing core/)
import '../models/quote.dart';                    // ← was '../../data/models/...' (too many ../)
import '../models/quote_item.dart';               // ← was '../../data/models/...' (too many ../)
import 'excel_export_web.dart' if (dart.library.io) 'excel_export_stub.dart';

class ExcelExportService {
  static final _currency = NumberFormat('#,##0.00');

  // ── Column indices (A=0 … N=13) ──────────────────────────────
  static const _A = 0;   // spacer
  static const _B = 1;   // No.
  static const _C = 2;   // Description start (merges C–F)
  static const _D = 3;
  static const _E = 4;
  static const _F = 5;   // Description end
  static const _G = 6;   // L (neck size)
  static const _H = 7;   // x / DIA
  static const _I = 8;   // W
  static const _J = 9;   // Qty
  static const _K = 10;  // spacer
  static const _L = 11;  // unit
  static const _M = 12;  // Unit price
  static const _N = 13;  // TOTAL

  // ── Colors (ARGB — 8 chars with FF prefix) ───────────────────
  static ExcelColor get _darkGreen  => ExcelColor.fromHexString('FF3A6B1A');
  static ExcelColor get _medGreen   => ExcelColor.fromHexString('FF5B8C2A');
  static ExcelColor get _lightGreen => ExcelColor.fromHexString('FFD4EDBA');
  static ExcelColor get _altRow     => ExcelColor.fromHexString('FFF7FBF3');
  static ExcelColor get _red        => ExcelColor.fromHexString('FFC0392B');
  static ExcelColor get _blue       => ExcelColor.fromHexString('FF1A5276');
  static ExcelColor get _grey       => ExcelColor.fromHexString('FF666666');

  // ══════════════════════════════════════════════════════════════
  // NECK SIZE PARSERS
  // Handles formats: "600 x 400", "600 X 400", "6 DIA", "150 DIA"
  // ══════════════════════════════════════════════════════════════
  static String _neckL(String ns) {
    final s = ns.trim().toUpperCase();
    if (s.contains('DIA')) return s.replaceAll('DIA', '').trim();
    final parts = s.split(RegExp(r'\s*[Xx×]\s*'));
    return parts.isNotEmpty ? parts[0].trim() : s;
  }

  static String _neckSep(String ns) =>
      ns.trim().toUpperCase().contains('DIA') ? 'DIA' : 'x';

  static String _neckW(String ns) {
    if (ns.trim().toUpperCase().contains('DIA')) return '';
    final parts = ns.trim().split(RegExp(r'\s*[Xx×]\s*'));
    return parts.length > 1 ? parts[1].trim() : '';
  }

  // ══════════════════════════════════════════════════════════════
  // ENTRY POINT
  // ══════════════════════════════════════════════════════════════
  static Future<dynamic> exportQuote(Quote quote) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');
    final sheet = excel['Quotation'];

    sheet.setColumnWidth(_A, 2);
    sheet.setColumnWidth(_B, 7);
    sheet.setColumnWidth(_C, 22);
    sheet.setColumnWidth(_D, 12);
    sheet.setColumnWidth(_E, 12);
    sheet.setColumnWidth(_F, 8);
    sheet.setColumnWidth(_G, 8);
    sheet.setColumnWidth(_H, 4);
    sheet.setColumnWidth(_I, 8);
    sheet.setColumnWidth(_J, 6);
    sheet.setColumnWidth(_K, 2);
    sheet.setColumnWidth(_L, 6);
    sheet.setColumnWidth(_M, 15);
    sheet.setColumnWidth(_N, 15);

    int r = 0;
    r = _header(sheet, r, quote);
    r = _tableHeader(sheet, r);
    r = _items(sheet, r, quote);
    r = _totals(sheet, r, quote);
    r = _notes(sheet, r);
    r = _signatures(sheet, r);

    final bytes = Uint8List.fromList(excel.encode()!);
    final fileName = '${quote.refNo}.xlsx';

    if (kIsWeb) {
      downloadExcelOnWeb(bytes, fileName);
      return null;
    } else {
      return getMobileFile(bytes, fileName);
    }
  }

  // ══════════════════════════════════════════════════════════════
  // HEADER BLOCK
  // ══════════════════════════════════════════════════════════════
  static int _header(Sheet sheet, int r, Quote quote) {
    // Banner
    sheet.setRowHeight(r, 32);
    _mwrite(sheet, r, _B, _N, AppConstants.companyName,
      CellStyle(
        backgroundColorHex: _darkGreen,
        fontColorHex: ExcelColor.white,
        bold: true, fontSize: 18,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      ));
    r++;

    // Tagline
    _mwrite(sheet, r, _B, _N, AppConstants.companyTagline,
      CellStyle(
        backgroundColorHex: _lightGreen,
        fontColorHex: _darkGreen,
        bold: true, italic: true, fontSize: 10,
        horizontalAlign: HorizontalAlign.Center,
      ));
    r++;

    // Address
    _mwrite(sheet, r, _B, _N,
      '${AppConstants.companyAddress}  |  ${AppConstants.companyPhone}  |  '
      '${AppConstants.companyFax}  |  ${AppConstants.companyWireless}  |  '
      'Email: ${AppConstants.companyEmail}  |  Website: ${AppConstants.companyWebsite}',
      CellStyle(fontSize: 8, fontColorHex: _grey));
    r++;
    r++; // spacer

    // ── COMPANY / DATE / REFERENCE NO. ───────────────────────
    _write(sheet, r, _B, 'COMPANY', _label());
    sheet.merge(_idx(_B, r), _idx(_K, r));
    _write(sheet, r, _L, 'DATE', _label(center: true));
    sheet.merge(_idx(_L, r), _idx(_M, r));
    _write(sheet, r, _N, 'REFERENCE NO.', _label(center: true));
    r++;

    sheet.setRowHeight(r, 22);
    _write(sheet, r, _B, quote.company,
      CellStyle(bold: true, fontSize: 13,
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        bottomBorder: Border(borderStyle: BorderStyle.Thin)));
    sheet.merge(_idx(_B, r), _idx(_K, r));

    _write(sheet, r, _L,
      DateFormat('dd-MMM-yy').format(quote.date).toUpperCase(),
      CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center,
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
        bottomBorder: Border(borderStyle: BorderStyle.Thin)));
    sheet.merge(_idx(_L, r), _idx(_M, r));

    _write(sheet, r, _N, quote.refNo,
      CellStyle(bold: true, fontSize: 12, fontColorHex: _blue,
        horizontalAlign: HorizontalAlign.Center,
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
        bottomBorder: Border(borderStyle: BorderStyle.Thin)));
    r++;

    _write(sheet, r, _B, quote.companyLocation,
      CellStyle(fontColorHex: _grey,
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
        bottomBorder: Border(borderStyle: BorderStyle.Thin)));
    sheet.merge(_idx(_B, r), _idx(_N, r));
    r++;

    // ── ATTENTION / PAYMENT TERMS ─────────────────────────────
    _write(sheet, r, _B, 'ATTENTION', _label());
    sheet.merge(_idx(_B, r), _idx(_K, r));
    _write(sheet, r, _L, 'PAYMENT TERMS', _label(center: true));
    sheet.merge(_idx(_L, r), _idx(_N, r));
    r++;

    sheet.setRowHeight(r, 22);
    _write(sheet, r, _B, quote.attention,
      CellStyle(bold: true, fontSize: 13,
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        bottomBorder: Border(borderStyle: BorderStyle.Thin)));
    sheet.merge(_idx(_B, r), _idx(_K, r));

    _write(sheet, r, _L, quote.paymentTerms,
      CellStyle(bold: true, fontColorHex: _red,
        horizontalAlign: HorizontalAlign.Center,
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
        bottomBorder: Border(borderStyle: BorderStyle.Thin)));
    sheet.merge(_idx(_L, r), _idx(_N, r));
    r++;

    _write(sheet, r, _B, quote.attentionTitle,
      CellStyle(fontColorHex: _grey,
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
        bottomBorder: Border(borderStyle: BorderStyle.Thin)));
    sheet.merge(_idx(_B, r), _idx(_N, r));
    r++;

    // ── PROJECT & LOCATION / LEADTIME ─────────────────────────
    _write(sheet, r, _B, 'PROJECT & LOCATION', _label());
    sheet.merge(_idx(_B, r), _idx(_K, r));
    _write(sheet, r, _L, 'LEADTIME', _label(center: true));
    sheet.merge(_idx(_L, r), _idx(_N, r));
    r++;

    sheet.setRowHeight(r, 45);
    _write(sheet, r, _B, quote.projectLocation,
      CellStyle(bold: true,
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        bottomBorder: Border(borderStyle: BorderStyle.Thin)));
    sheet.merge(_idx(_B, r), _idx(_K, r));

    _write(sheet, r, _L,
      quote.leadtime.isNotEmpty
        ? quote.leadtime
        : AppConstants.defaultLeadtime,
      CellStyle(bold: true, fontColorHex: _blue,
        horizontalAlign: HorizontalAlign.Center,
        textWrapping: TextWrapping.WrapText,
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
        bottomBorder: Border(borderStyle: BorderStyle.Thin)));
    sheet.merge(_idx(_L, r), _idx(_N, r));
    r++;

    _write(sheet, r, _B, quote.supplyDescription,
      CellStyle(bold: true,
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
        bottomBorder: Border(borderStyle: BorderStyle.Thin)));
    sheet.merge(_idx(_B, r), _idx(_N, r));
    r++;
    r++; // spacer

    return r;
  }

  // ══════════════════════════════════════════════════════════════
  // TABLE HEADER (2 rows)
  // ══════════════════════════════════════════════════════════════
  static int _tableHeader(Sheet sheet, int r) {
    // Row 1 — group headers
    sheet.setRowHeight(r, 22);
    _write(sheet, r, _B, 'No.',             _th());
    _write(sheet, r, _C, 'Description',     _th());
    sheet.merge(_idx(_C, r), _idx(_F, r));
    _write(sheet, r, _G, 'Neck size in mm', _th(wrap: true));
    sheet.merge(_idx(_G, r), _idx(_I, r));
    _write(sheet, r, _J, 'Qty',             _th());
    sheet.merge(_idx(_J, r), _idx(_L, r));
    _write(sheet, r, _M, 'Unit price',      _th());
    _write(sheet, r, _N, 'TOTAL',           _th());
    r++;

    // Row 2 — L / x / W sub-headers
    sheet.setRowHeight(r, 16);
    _write(sheet, r, _B, '',  _th());
    _write(sheet, r, _C, '',  _th());
    sheet.merge(_idx(_C, r), _idx(_F, r));
    _write(sheet, r, _G, 'L', _th());
    _write(sheet, r, _H, 'x', _th());
    _write(sheet, r, _I, 'W', _th());
    _write(sheet, r, _J, '',  _th());
    sheet.merge(_idx(_J, r), _idx(_L, r));
    _write(sheet, r, _M, '',  _th());
    _write(sheet, r, _N, '',  _th());
    r++;

    return r;
  }

  // ══════════════════════════════════════════════════════════════
  // ITEMS
  // ══════════════════════════════════════════════════════════════
  static int _items(Sheet sheet, int r, Quote quote) {
    int num = 1;
    bool alt = false;

    for (final entry in quote.groupedBySection.entries) {
      // Section header row
      _mwrite(sheet, r, _B, _N, entry.key.toUpperCase(),
        CellStyle(
          backgroundColorHex: _lightGreen,
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
          leftBorder: Border(borderStyle: BorderStyle.Thin),
          rightBorder: Border(borderStyle: BorderStyle.Thin),
          topBorder: Border(borderStyle: BorderStyle.Thin),
          bottomBorder: Border(borderStyle: BorderStyle.Thin),
        ));
      r++;

      for (final item in entry.value) {
        final bg = alt ? _altRow : ExcelColor.white;
        alt = !alt;

        // No.
        _write(sheet, r, _B,
          '${num.toStringAsFixed(1)}',
          _row(bg, align: HorizontalAlign.Center));

        // Description — fullDescription appends [AL]/[GI] material
        _write(sheet, r, _C, item.fullDescription, _row(bg));
        sheet.merge(_idx(_C, r), _idx(_F, r));

        // Neck size parsed from item.neckSize
        _write(sheet, r, _G, _neckL(item.neckSize), _row(bg, align: HorizontalAlign.Center));
        _write(sheet, r, _H, _neckSep(item.neckSize), _row(bg, align: HorizontalAlign.Center));
        _write(sheet, r, _I, _neckW(item.neckSize), _row(bg, align: HorizontalAlign.Center));

        // Qty
        final qtyCell = sheet.cell(_idx(_J, r));
        qtyCell.value = IntCellValue(item.qty);
        qtyCell.cellStyle = _row(bg, align: HorizontalAlign.Center);

        // spacer + unit (from item.unit)
        _write(sheet, r, _K, '', _row(bg));
        _write(sheet, r, _L, item.unit, _row(bg));

        // Unit price
        _write(sheet, r, _M,
          _currency.format(item.unitPrice),
          _row(bg, align: HorizontalAlign.Right));

        // Total
        _write(sheet, r, _N,
          _currency.format(item.total),
          _row(bg, align: HorizontalAlign.Right));

        r++;
        num++;
      }
    }

    return r;
  }

  // ══════════════════════════════════════════════════════════════
  // TOTALS
  // ══════════════════════════════════════════════════════════════
  static int _totals(Sheet sheet, int r, Quote quote) {
    r++; // spacer

    // TOTAL QTY
    _write(sheet, r, _J, 'TOTAL QTY',
      CellStyle(bold: true, horizontalAlign: HorizontalAlign.Right,
        topBorder: Border(borderStyle: BorderStyle.Medium),
        bottomBorder: Border(borderStyle: BorderStyle.Medium),
        leftBorder: Border(borderStyle: BorderStyle.Medium)));
    sheet.merge(_idx(_J, r), _idx(_M, r));

    final tqCell = sheet.cell(_idx(_N, r));
    tqCell.value = IntCellValue(quote.totalQty);
    tqCell.cellStyle = CellStyle(bold: true,
      horizontalAlign: HorizontalAlign.Center,
      topBorder: Border(borderStyle: BorderStyle.Medium),
      bottomBorder: Border(borderStyle: BorderStyle.Medium),
      rightBorder: Border(borderStyle: BorderStyle.Medium));
    r++;

    // Subtotal 1
    _write(sheet, r, _L, 'Subtotal 1',
      CellStyle(bold: true, horizontalAlign: HorizontalAlign.Right,
        bottomBorder: Border(borderStyle: BorderStyle.Thin)));
    sheet.merge(_idx(_L, r), _idx(_M, r));

    _write(sheet, r, _N, _currency.format(quote.total),
      CellStyle(bold: true, horizontalAlign: HorizontalAlign.Right,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin)));
    r++;

    // Total (Vat inc) — dark green
    sheet.setRowHeight(r, 24);
    _write(sheet, r, _L, 'Total (Vat inc)',
      CellStyle(bold: true, fontSize: 12,
        backgroundColorHex: _darkGreen,
        fontColorHex: ExcelColor.white,
        horizontalAlign: HorizontalAlign.Right,
        topBorder: Border(borderStyle: BorderStyle.Medium, borderColorHex: _darkGreen),
        bottomBorder: Border(borderStyle: BorderStyle.Medium, borderColorHex: _darkGreen),
        leftBorder: Border(borderStyle: BorderStyle.Medium, borderColorHex: _darkGreen)));
    sheet.merge(_idx(_L, r), _idx(_M, r));

    _write(sheet, r, _N, _currency.format(quote.total),
      CellStyle(bold: true, fontSize: 13,
        backgroundColorHex: _darkGreen,
        fontColorHex: ExcelColor.white,
        horizontalAlign: HorizontalAlign.Right,
        topBorder: Border(borderStyle: BorderStyle.Medium, borderColorHex: _darkGreen),
        bottomBorder: Border(borderStyle: BorderStyle.Medium, borderColorHex: _darkGreen),
        rightBorder: Border(borderStyle: BorderStyle.Medium, borderColorHex: _darkGreen)));
    r++;

    return r;
  }

  // ══════════════════════════════════════════════════════════════
  // NOTES + TERMS
  // ══════════════════════════════════════════════════════════════
  static int _notes(Sheet sheet, int r) {
    r++;

    // NOTES heading
    _write(sheet, r, _B, 'NOTES',
      CellStyle(bold: true, underline: Underline.Single,
        topBorder: Border(borderStyle: BorderStyle.Thin)));
    sheet.merge(_idx(_B, r), _idx(_J, r));
    r++;

    // Notes — from AppConstants
    for (final note in AppConstants.pdfNotes) {
      _write(sheet, r, _B, note,
        CellStyle(fontSize: 9, fontColorHex: _blue));
      sheet.merge(_idx(_B, r), _idx(_N, r));
      r++;
    }

    r++;

    // Terms — from AppConstants
    for (final term in AppConstants.pdfTerms) {
      _write(sheet, r, _B, term,
        CellStyle(fontSize: 8, fontColorHex: _grey));
      sheet.merge(_idx(_B, r), _idx(_N, r));
      r++;
    }

    return r;
  }

  // ══════════════════════════════════════════════════════════════
  // SIGNATURES + FOOTER
  // ══════════════════════════════════════════════════════════════
  static int _signatures(Sheet sheet, int r) {
    final roy   = AppConstants.staffInfo['roy']!;
    final issah = AppConstants.staffInfo['issah']!;

    r++;

    _write(sheet, r, _B, 'Prepared by:',
      CellStyle(fontSize: 9, fontColorHex: _grey));
    _write(sheet, r, _L, 'Accepted and Conformed by:',
      CellStyle(bold: true, horizontalAlign: HorizontalAlign.Right));
    sheet.merge(_idx(_L, r), _idx(_N, r));
    r += 2;

    _write(sheet, r, _B, roy['name']!,   CellStyle(bold: true));
    _write(sheet, r, _F, issah['name']!, CellStyle(bold: true));
    _write(sheet, r, _L, '_______________________________',
      CellStyle(horizontalAlign: HorizontalAlign.Center));
    sheet.merge(_idx(_L, r), _idx(_N, r));
    r++;

    _write(sheet, r, _B, roy['title']!,
      CellStyle(fontSize: 9, fontColorHex: _grey));
    _write(sheet, r, _F, issah['title']!,
      CellStyle(fontSize: 9, fontColorHex: _grey));
    _write(sheet, r, _L, "Clients' Signature over printed name",
      CellStyle(fontSize: 9, fontColorHex: _grey,
        horizontalAlign: HorizontalAlign.Center));
    sheet.merge(_idx(_L, r), _idx(_N, r));
    r++;

    _write(sheet, r, _B, 'Mobile: ${roy['mobile']!}',
      CellStyle(fontSize: 9, fontColorHex: _blue));
    _write(sheet, r, _F, 'Mobile: ${issah['mobile']!}',
      CellStyle(fontSize: 9, fontColorHex: _blue));
    r++;

    _write(sheet, r, _B, 'Email: ${roy['email']!}',
      CellStyle(fontSize: 9, fontColorHex: _blue));
    _write(sheet, r, _F, 'Email: ${issah['email']!}',
      CellStyle(fontSize: 9, fontColorHex: _blue));
    r += 2;

    // Footer
    _mwrite(sheet, r, _B, _N,
      '"Thank you for giving us the opportunity to quote on your requirements."',
      CellStyle(italic: true, fontSize: 10, fontColorHex: _medGreen,
        horizontalAlign: HorizontalAlign.Center));
    r++;

    return r;
  }

  // ══════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════
  static CellIndex _idx(int col, int row) =>
    CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row);

  static void _write(Sheet sheet, int r, int c, String value, CellStyle style) {
    final cell = sheet.cell(_idx(c, r));
    cell.value = TextCellValue(value);
    cell.cellStyle = style;
  }

  /// Writes value to top-left cell only then merges — slave cells stay untouched
  static void _mwrite(Sheet sheet, int r, int cStart, int cEnd,
      String value, CellStyle style) {
    _write(sheet, r, cStart, value, style);
    if (cStart < cEnd) sheet.merge(_idx(cStart, r), _idx(cEnd, r));
  }

  static CellStyle _label({bool center = false}) => CellStyle(
    backgroundColorHex: ExcelColor.fromHexString('FFF0F0F0'),
    bold: true, fontSize: 9,
    horizontalAlign: center ? HorizontalAlign.Center : HorizontalAlign.Left,
    leftBorder: Border(borderStyle: BorderStyle.Thin),
    rightBorder: Border(borderStyle: BorderStyle.Thin),
    topBorder: Border(borderStyle: BorderStyle.Thin),
    bottomBorder: Border(borderStyle: BorderStyle.Thin),
  );

  static CellStyle _th({bool wrap = false}) => CellStyle(
    backgroundColorHex: ExcelColor.fromHexString('FF3A6B1A'),
    fontColorHex: ExcelColor.white,
    bold: true,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    textWrapping: wrap ? TextWrapping.WrapText : TextWrapping.Clip,
    leftBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.white),
    rightBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.white),
    topBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.white),
    bottomBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.white),
  );

  static CellStyle _row(ExcelColor bg,
      {HorizontalAlign align = HorizontalAlign.Left}) =>
    CellStyle(
      backgroundColorHex: bg,
      horizontalAlign: align,
      leftBorder: Border(borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('FFCCCCCC')),
      rightBorder: Border(borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('FFCCCCCC')),
      topBorder: Border(borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('FFCCCCCC')),
      bottomBorder: Border(borderStyle: BorderStyle.Thin,
        borderColorHex: ExcelColor.fromHexString('FFCCCCCC')),
    );
}