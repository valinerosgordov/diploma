import 'package:flutter/material.dart';
import 'package:ml_practice/models/app_colors.dart';
import 'package:ml_practice/models/report_data.dart';
import 'package:ml_practice/models/report_history.dart';
import 'package:ml_practice/services/report_history_service.dart';
import 'package:ml_practice/services/threat_assessment_service.dart';
import 'package:ml_practice/widgets/expanded_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as excel;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class ReportGenerationScreen extends StatefulWidget {
  final ReportData reportData;

  const ReportGenerationScreen({super.key, required this.reportData});

  @override
  State<ReportGenerationScreen> createState() => _ReportGenerationScreenState();
}

class _ReportGenerationScreenState extends State<ReportGenerationScreen> {
  int selectedIndex = 0;
  bool isLoading = false;
  final ReportHistoryService _historyService = ReportHistoryService();

  String get _threatLevel {
    final threats = widget.reportData.threatAssessments.values.toList();
    if (threats.isEmpty) return ThreatLevel.safe.label;
    return ThreatAssessmentService.aggregateLevel(threats).label;
  }

  Future<void> _generateReport() async {
    if (!await _requestPermissions()) return;

    setState(() => isLoading = true);

    try {
      final now = DateTime.now();
      final timestamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final fileType = selectedIndex == 0 ? 'xlsx' : 'pdf';
      final filename = 'file_analysis_report_$timestamp.$fileType';

      final directory = await _getOutputDirectory();
      if (directory == null) throw Exception('Could not access storage');

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final filePath = p.join(directory.path, filename);

      if (selectedIndex == 0) {
        await _generateExcelReport(directory.path, filename);
      } else {
        await _generatePdfReport(directory.path, filename);
      }

      await _historyService.addReport(
        ReportHistory(
          filePath: filePath,
          fileName: filename,
          generatedAt: DateTime.now(),
          fileType: fileType,
          totalFiles: widget.reportData.totalFiles,
        ),
      );

      if (!mounted) return;
      _showSuccessDialog(filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<bool> _requestPermissions() async {
    if (!Platform.isAndroid) return true;

    final manageStatus = await Permission.manageExternalStorage.status;
    final storageStatus = await Permission.storage.status;

    if (manageStatus.isGranted || storageStatus.isGranted) return true;

    final result = await Permission.manageExternalStorage.request();
    if (result.isGranted) return true;

    final storageResult = await Permission.storage.request();
    if (storageResult.isGranted) return true;

    if (!mounted) return false;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Storage permission is required to save reports. '
          'Please enable storage permissions in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    return false;
  }

  Future<Directory?> _getOutputDirectory() async {
    if (Platform.isAndroid) {
      try {
        final directory = await getExternalStorageDirectory();
        if (directory == null) return await getApplicationDocumentsDirectory();

        final parts = directory.path.split('/');
        final buffer = StringBuffer();
        for (int i = 1; i < parts.length; i++) {
          if (parts[i] == 'Android') break;
          buffer.write('/${parts[i]}');
        }
        buffer.write('/Download');
        return Directory(buffer.toString());
      } catch (_) {
        return await getApplicationDocumentsDirectory();
      }
    }
    return await getApplicationDocumentsDirectory();
  }

  void _showSuccessDialog(String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Generated'),
        content: Text('Report saved to:\n$filePath'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () async {
              await Share.shareXFiles(
                [XFile(filePath)],
                text: 'File Analysis Report',
              );
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  // --- PDF Generation ---

  Future<void> _generatePdfReport(String directory, String filename) async {
    final pageFormat = PdfPageFormat.a5.copyWith(
      marginLeft: 10,
      marginRight: 10,
      marginTop: 10,
      marginBottom: 10,
    );

    final pdf = pw.Document(
      compress: true,
      version: PdfVersion.pdf_1_4,
      pageMode: PdfPageMode.none,
    );

    final theme = pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
    );

    const itemsPerPage = 2;
    final data = widget.reportData;

    // Header + Summary
    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(10),
        build: (context) => [
          _pdfHeader(),
          pw.SizedBox(height: 10),
          _pdfSection('1. Report Header', [
            _infoRow('Incident Name', 'File Analysis Report'),
            _infoRow('Date & Time', DateTime.now().toUtc().toString()),
            _infoRow('Analyst Name', 'System Generated'),
            _infoRow('Threat Level', _threatLevel, isHighlight: true),
          ]),
          pw.SizedBox(height: 10),
          _pdfSection('2. Summary', [
            _infoRow('Total Files', '${data.totalFiles} files'),
            _infoRow('Photo Classifications',
                '${data.photoClassifications.length} images'),
            _infoRow('Content Classifications',
                '${data.contentClassifications.length} files'),
            _infoRow('Duplicate Detections',
                '${data.duplicateDetections.length} comparisons'),
            _infoRow(
                'Auto-Tagged', '${data.autoTags.length} files'),
            _infoRow('Security Issues',
                '${data.sensitiveDataFindings.length} files with sensitive data'),
            _infoRow('Threat Assessments',
                '${data.threatAssessments.length} files with threats'),
          ]),
        ],
      ),
    );

    // Photo Classifications
    _addChunkedSection(
      pdf: pdf,
      theme: theme,
      pageFormat: pageFormat,
      title: '3. Photo Classifications',
      entries: data.photoClassifications.entries.toList(),
      itemsPerPage: itemsPerPage,
      buildItem: (entry) => [
        _infoRow('File', p.basename(entry.key)),
        _infoRow('Category', entry.value.category),
        _infoRow('ML Labels', entry.value.mlLabels.take(3).join(', ')),
        _infoRow(
          'Confidences',
          entry.value.confidences
              .take(3)
              .map((c) => '${(c * 100).toStringAsFixed(1)}%')
              .join(', '),
        ),
        pw.SizedBox(height: 8),
      ],
    );

    // Content Classifications
    _addChunkedSection(
      pdf: pdf,
      theme: theme,
      pageFormat: pageFormat,
      title: '4. Content Classifications',
      entries: data.contentClassifications.entries.toList(),
      itemsPerPage: itemsPerPage,
      buildItem: (entry) => [
        _infoRow('File', p.basename(entry.key)),
        _infoRow('Content Type', entry.value.contentType),
        _infoRow(
            'Keywords', entry.value.detectedKeywords.take(5).join(', ')),
        pw.SizedBox(height: 8),
      ],
    );

    // Duplicate Detections
    _addChunkedSection(
      pdf: pdf,
      theme: theme,
      pageFormat: pageFormat,
      title: '5. Duplicate Detections',
      entries: data.duplicateDetections.entries.toList(),
      itemsPerPage: itemsPerPage,
      buildItem: (entry) => [
        _infoRow('File', p.basename(entry.key)),
        _infoRow('Is Duplicate', entry.value.isDuplicate.toString()),
        if (entry.value.isDuplicate)
          _infoRow('Matched With', entry.value.matchedWith ?? 'N/A'),
        _infoRow('Similarity',
            '${(entry.value.similarityScore * 100).toStringAsFixed(1)}%'),
        _infoRow('Match Type', entry.value.matchType.toString()),
        pw.SizedBox(height: 8),
      ],
    );

    // Auto Tags
    _addChunkedSection(
      pdf: pdf,
      theme: theme,
      pageFormat: pageFormat,
      title: '6. Auto Tags',
      entries: data.autoTags.entries.toList(),
      itemsPerPage: itemsPerPage,
      buildItem: (entry) => [
        _infoRow('File', p.basename(entry.key)),
        _infoRow('Tags', entry.value.tags.join(', ')),
        _infoRow(
          'Confidences',
          entry.value.confidences
              .map((c) => '${(c * 100).toStringAsFixed(1)}%')
              .join(', '),
        ),
        pw.SizedBox(height: 8),
      ],
    );

    // Sensitive Data Findings
    _addChunkedSection(
      pdf: pdf,
      theme: theme,
      pageFormat: pageFormat,
      title: '7. Sensitive Data Findings',
      entries: data.sensitiveDataFindings.entries.toList(),
      itemsPerPage: itemsPerPage,
      buildItem: (entry) => [
        _infoRow('File', p.basename(entry.key)),
        _infoRow('Total Findings', '${entry.value.totalFindings}'),
        _infoRow(
          'Types',
          entry.value.summary.entries
              .map((e) => '${e.key.label}: ${e.value}')
              .join(', '),
        ),
        pw.SizedBox(height: 8),
      ],
    );

    // Threat Assessments
    _addChunkedSection(
      pdf: pdf,
      theme: theme,
      pageFormat: pageFormat,
      title: '8. Threat Assessments',
      entries: data.threatAssessments.entries.toList(),
      itemsPerPage: itemsPerPage,
      buildItem: (entry) => [
        _infoRow('File', p.basename(entry.key)),
        _infoRow('Threat Level', entry.value.overallLevel.label),
        _infoRow('Risk Score', '${entry.value.riskScore}/100'),
        ...entry.value.findings.map(
          (f) => _infoRow('Finding', f.detail),
        ),
        pw.SizedBox(height: 8),
      ],
    );

    // Performance Metrics
    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(10),
        build: (context) => [
          _pdfSection('9. ML Model Performance', [
            _infoRow(
              'Avg Confidence (Photo)',
              '${_avgConfidence(data.photoClassifications.values.expand((r) => r.confidences))}%',
            ),
            _infoRow(
              'Avg Confidence (Tags)',
              '${_avgConfidence(data.autoTags.values.expand((r) => r.confidences))}%',
            ),
            _infoRow(
              'Duplicate Detection Rate',
              '${_duplicateRate()}%',
            ),
          ]),
        ],
      ),
    );

    // Save
    final file = File('$directory/$filename');
    final bytes = await pdf.save();
    await file.writeAsBytes(bytes);
  }

  void _addChunkedSection<T>({
    required pw.Document pdf,
    required pw.ThemeData theme,
    required PdfPageFormat pageFormat,
    required String title,
    required List<T> entries,
    required int itemsPerPage,
    required List<pw.Widget> Function(T) buildItem,
  }) {
    for (var i = 0; i < entries.length; i += itemsPerPage) {
      final chunk = entries.skip(i).take(itemsPerPage);
      final widgets = chunk.expand(buildItem).toList();

      pdf.addPage(
        pw.MultiPage(
          theme: theme,
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(10),
          maxPages: 1,
          build: (context) => [_pdfSection(title, widgets)],
        ),
      );
    }
  }

  pw.Widget _pdfHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue700,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Center(
        child: pw.Text(
          'File Analysis Report',
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  pw.Widget _pdfSection(String title, List<pw.Widget> children) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300),
              ),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
              ),
            ),
          ),
          pw.SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  pw.Widget _infoRow(String label, String value, {bool isHighlight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                color: isHighlight ? PdfColors.red : PdfColors.black,
                fontWeight: isHighlight ? pw.FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _avgConfidence(Iterable<double> confidences) {
    final list = confidences.toList();
    if (list.isEmpty) return '0.0';
    final avg = list.reduce((a, b) => a + b) / list.length;
    return (avg * 100).toStringAsFixed(1);
  }

  String _duplicateRate() {
    final duplicates = widget.reportData.duplicateDetections;
    if (duplicates.isEmpty) return '0.0';

    final detected =
        duplicates.values.where((d) => d.isDuplicate).length;
    return (detected / duplicates.length * 100).toStringAsFixed(1);
  }

  // --- Excel Generation ---

  Future<void> _generateExcelReport(String directory, String filename) async {
    final workbook = excel.Excel.createExcel();
    final data = widget.reportData;

    // Summary Sheet
    final summary = workbook['Summary'];
    _excelHeader(summary);
    _excelSummary(summary, data);

    // File Analysis Sheet
    final analysis = workbook['File Analysis'];
    _excelFileAnalysis(analysis, data);

    // Security Sheet
    final security = workbook['Security'];
    _excelSecurity(security, data);

    // Performance Sheet
    final perf = workbook['Performance'];
    _excelPerformance(perf, data);

    final file = File('$directory/$filename');
    await file.writeAsBytes(workbook.encode()!);
  }

  void _excelHeader(excel.Sheet sheet) {
    final titleCell = sheet.cell(excel.CellIndex.indexByString('A1'));
    titleCell.value = excel.TextCellValue('File Analysis Report');
    titleCell.cellStyle = excel.CellStyle(bold: true, fontSize: 16);
    sheet.merge(
      excel.CellIndex.indexByString('A1'),
      excel.CellIndex.indexByString('C1'),
    );

    final headers = [
      ['Incident Name', 'File Analysis Report'],
      ['Date & Time', DateTime.now().toUtc().toString()],
      ['Analyst Name', 'System Generated'],
      ['Threat Level', _threatLevel],
    ];

    for (var i = 0; i < headers.length; i++) {
      final row = i + 3;
      final label = sheet.cell(excel.CellIndex.indexByString('A$row'));
      final value = sheet.cell(excel.CellIndex.indexByString('B$row'));
      label.value = excel.TextCellValue(headers[i][0]);
      value.value = excel.TextCellValue(headers[i][1]);
      label.cellStyle = excel.CellStyle(bold: true);
    }
  }

  void _excelSummary(excel.Sheet sheet, ReportData data) {
    int row = 8;
    final header = sheet.cell(excel.CellIndex.indexByString('A$row'));
    header.value = excel.TextCellValue('ML Analysis Summary');
    header.cellStyle = excel.CellStyle(bold: true, fontSize: 14);
    row += 2;

    final summaryData = [
      ['Total Files Analyzed', '${data.totalFiles}'],
      ['Photo Classifications', '${data.photoClassifications.length} images'],
      ['Content Classifications', '${data.contentClassifications.length} files'],
      ['Duplicate Detections', '${data.duplicateDetections.length} comparisons'],
      ['Auto-Tagged Files', '${data.autoTags.length} files'],
      ['Sensitive Data Files', '${data.sensitiveDataFindings.length} files'],
      ['Threat Detections', '${data.threatAssessments.length} files'],
    ];

    for (final item in summaryData) {
      final label = sheet.cell(excel.CellIndex.indexByString('A$row'));
      final value = sheet.cell(excel.CellIndex.indexByString('B$row'));
      label.value = excel.TextCellValue(item[0]);
      value.value = excel.TextCellValue(item[1]);
      label.cellStyle = excel.CellStyle(bold: true);
      row++;
    }
  }

  void _excelFileAnalysis(excel.Sheet sheet, ReportData data) {
    int row = 1;

    // Photo Classifications
    row = _addExcelSection(sheet, row, 'Photo Classifications', [
      ['File', 'Category', 'ML Labels', 'Confidences'],
      ...data.photoClassifications.entries.map((e) => [
            p.basename(e.key),
            e.value.category,
            e.value.mlLabels.join(', '),
            e.value.confidences
                .map((c) => '${(c * 100).toStringAsFixed(1)}%')
                .join(', '),
          ]),
    ]);
    row += 2;

    // Content Classifications
    row = _addExcelSection(sheet, row, 'Content Classifications', [
      ['File', 'Content Type', 'Keywords'],
      ...data.contentClassifications.entries.map((e) => [
            p.basename(e.key),
            e.value.contentType,
            e.value.detectedKeywords.join(', '),
          ]),
    ]);
    row += 2;

    // Duplicate Detections
    row = _addExcelSection(sheet, row, 'Duplicate Detections', [
      ['File', 'Is Duplicate', 'Matched With', 'Similarity', 'Match Type'],
      ...data.duplicateDetections.entries.map((e) => [
            p.basename(e.key),
            e.value.isDuplicate.toString(),
            e.value.isDuplicate ? (e.value.matchedWith ?? 'N/A') : 'N/A',
            '${(e.value.similarityScore * 100).toStringAsFixed(1)}%',
            e.value.matchType.toString(),
          ]),
    ]);
    row += 2;

    // Auto Tags
    _addExcelSection(sheet, row, 'Auto Tags', [
      ['File', 'Tags', 'Confidences'],
      ...data.autoTags.entries.map((e) => [
            p.basename(e.key),
            e.value.tags.join(', '),
            e.value.confidences
                .map((c) => '${(c * 100).toStringAsFixed(1)}%')
                .join(', '),
          ]),
    ]);
  }

  void _excelPerformance(excel.Sheet sheet, ReportData data) {
    int row = 1;
    final header = sheet.cell(excel.CellIndex.indexByString('A$row'));
    header.value = excel.TextCellValue('ML Model Performance');
    header.cellStyle = excel.CellStyle(bold: true, fontSize: 14);
    row += 2;

    final metrics = [
      [
        'Average Confidence (Photo)',
        '${_avgConfidence(data.photoClassifications.values.expand((r) => r.confidences))}%',
      ],
      [
        'Average Confidence (Tags)',
        '${_avgConfidence(data.autoTags.values.expand((r) => r.confidences))}%',
      ],
      ['Duplicate Detection Rate', '${_duplicateRate()}%'],
    ];

    for (final metric in metrics) {
      final label = sheet.cell(excel.CellIndex.indexByString('A$row'));
      final value = sheet.cell(excel.CellIndex.indexByString('B$row'));
      label.value = excel.TextCellValue(metric[0]);
      value.value = excel.TextCellValue(metric[1]);
      label.cellStyle = excel.CellStyle(bold: true);
      row++;
    }
  }

  void _excelSecurity(excel.Sheet sheet, ReportData data) {
    int row = 1;

    // Sensitive Data
    row = _addExcelSection(sheet, row, 'Sensitive Data Findings', [
      ['File', 'Total Findings', 'Types'],
      ...data.sensitiveDataFindings.entries.map((e) => [
            p.basename(e.key),
            '${e.value.totalFindings}',
            e.value.summary.entries
                .map((s) => '${s.key.label}: ${s.value}')
                .join(', '),
          ]),
    ]);
    row += 2;

    // Threat Assessments
    _addExcelSection(sheet, row, 'Threat Assessments', [
      ['File', 'Threat Level', 'Risk Score', 'Findings'],
      ...data.threatAssessments.entries.map((e) => [
            p.basename(e.key),
            e.value.overallLevel.label,
            '${e.value.riskScore}/100',
            e.value.findings.map((f) => f.detail).join('; '),
          ]),
    ]);
  }

  int _addExcelSection(
    excel.Sheet sheet,
    int startRow,
    String title,
    List<List<String>> data,
  ) {
    final titleCell = sheet.cell(excel.CellIndex.indexByString('A$startRow'));
    titleCell.value = excel.TextCellValue(title);
    titleCell.cellStyle = excel.CellStyle(bold: true, fontSize: 12);
    sheet.merge(
      excel.CellIndex.indexByString('A$startRow'),
      excel.CellIndex.indexByString('E$startRow'),
    );

    int currentRow = startRow + 2;
    for (final row in data) {
      for (var i = 0; i < row.length; i++) {
        final cell = sheet.cell(
          excel.CellIndex.indexByString(
            '${String.fromCharCode(65 + i)}$currentRow',
          ),
        );
        cell.value = excel.TextCellValue(row[i]);

        if (currentRow == startRow + 2) {
          cell.cellStyle = excel.CellStyle(
            bold: true,
            backgroundColorHex: excel.ExcelColor.fromHexString('#E3E3E3'),
          );
        }
      }
      currentRow++;
    }
    return currentRow;
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Export Report'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const Spacer(),
              // Format selector
              Row(
                children: [
                  _formatBox(
                    text: 'Excel',
                    icon: Icons.table_chart_rounded,
                    color: const Color(0xFF00B894),
                    isActive: selectedIndex == 0,
                    onTap: () => setState(() => selectedIndex = 0),
                  ),
                  const SizedBox(width: 12),
                  _formatBox(
                    text: 'PDF',
                    icon: Icons.picture_as_pdf_rounded,
                    color: AppColors.error,
                    isActive: selectedIndex == 1,
                    onTap: () => setState(() => selectedIndex = 1),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Column(
                  children: [
                    _summaryRow('Files analyzed',
                        '${widget.reportData.totalFiles}'),
                    _summaryRow('Threat level', _threatLevel),
                    _summaryRow('Sensitive data files',
                        '${widget.reportData.sensitiveDataFindings.length}'),
                    _summaryRow('Duplicates found',
                        '${widget.reportData.duplicateDetections.values.where((d) => d.isDuplicate).length}'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (isLoading)
                const CircularProgressIndicator(color: AppColors.primary)
              else
                ExpandedButton(
                  action: _generateReport,
                  icon: const Icon(Icons.download_rounded, size: 20),
                  text:
                      'Export ${selectedIndex == 0 ? 'Excel' : 'PDF'}',
                ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textHint, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _formatBox({
    required String text,
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 110,
          decoration: BoxDecoration(
            gradient: isActive ? null : AppColors.cardGradient,
            color: isActive ? color.withValues(alpha: 0.12) : null,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? color : AppColors.border,
              width: isActive ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                text,
                style: TextStyle(
                  color: isActive ? color : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
