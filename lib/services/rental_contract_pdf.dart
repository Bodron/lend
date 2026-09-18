import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/rental_mode.dart';
import 'products_api.dart';

class RentalContractPdfInput {
  const RentalContractPdfInput({
    required this.product,
    required this.rentalMode,
    required this.startDate,
    required this.endDate,
    required this.pickupTime,
    required this.returnTime,
    required this.rentalHours,
    required this.rentalDays,
    required this.subtotal,
    required this.serviceFee,
    required this.total,
    required this.signaturePoints,
  });

  final LendProduct product;
  final RentalMode rentalMode;
  final DateTime startDate;
  final DateTime endDate;
  final String pickupTime;
  final String returnTime;
  final int rentalHours;
  final int rentalDays;
  final int subtotal;
  final int serviceFee;
  final int total;
  final List<ui.Offset?> signaturePoints;
}

Future<Uint8List> buildMockRentalContractPdf(
  RentalContractPdfInput input,
) async {
  final signaturePng = await _signatureToPng(input.signaturePoints);
  final signatureImage = signaturePng == null
      ? null
      : pw.MemoryImage(signaturePng);
  final document = pw.Document();
  final duration = input.rentalMode == RentalMode.hour
      ? '${input.rentalHours} ore'
      : input.rentalMode == RentalMode.month
      ? '1 luna'
      : '${input.rentalDays} zile';

  document.addPage(
    pw.MultiPage(
      pageTheme: const pw.PageTheme(
        margin: pw.EdgeInsets.all(36),
        pageFormat: PdfPageFormat.a4,
      ),
      build: (context) => [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'LEND',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#30578F'),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Contract mock de inchiriere'),
              ],
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#EEF3FA'),
                borderRadius: pw.BorderRadius.circular(20),
              ),
              child: pw.Text('Securizat de Lend'),
            ),
          ],
        ),
        pw.SizedBox(height: 28),
        pw.Text(
          'Contract de inchiriere bun',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 16),
        _infoGrid([
          ('Bun inchiriat', input.product.title),
          ('Categorie', input.product.category),
          ('Proprietar', input.product.ownerName),
          ('Locatie', '${input.product.city}, ${input.product.address}'),
          (
            'Perioada',
            '${_formatDate(input.startDate)} - ${_formatDate(input.endDate)}',
          ),
          ('Program', '${input.pickupTime} - ${input.returnTime}'),
          ('Durata', duration),
          ('Total', '${input.total} RON'),
        ]),
        pw.SizedBox(height: 24),
        _section(
          '1. Termeni generali',
          'Acest acord stabileste conditiile sub care proprietarul ofera bunul '
              'spre folosinta temporara locatarului pentru perioada specificata. '
              'Documentul este un model generat in aplicatia Lend si poate fi '
              'inlocuit ulterior cu un contract juridic complet.',
        ),
        _section(
          '2. Predare si retur',
          'Predarea se face la ora ${input.pickupTime}, iar returul la ora '
              '${input.returnTime}. Locatarul confirma ca va returna bunul la '
              'timp, in aceeasi stare in care l-a primit, cu exceptia uzurii normale.',
        ),
        _section(
          '3. Responsabilitate',
          'Locatarul isi asuma raspunderea pentru folosirea corecta a bunului '
              'pe durata inchirierii. Orice deteriorare, pierdere sau intarziere '
              'poate duce la retinerea partiala sau totala a garantiei.',
        ),
        _section(
          '4. Plata si garantie',
          'Subtotal: ${input.subtotal} RON. Taxa serviciu: ${input.serviceFee} RON. '
              'Total de plata: ${input.total} RON. Garantia este administrata '
              'prin platforma Lend conform regulilor aplicatiei.',
        ),
        _section(
          '5. Incetarea contractului',
          'Contractul inceteaza automat la finalul perioadei inchiriate sau prin '
              'acordul ambelor parti, exprimat in scris prin mesageria aplicatiei.',
        ),
        pw.SizedBox(height: 28),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _signatureBox(
                title: 'Semnatura proprietar',
                child: pw.Center(
                  child: pw.Text(
                    input.product.ownerName.isEmpty
                        ? 'Proprietar Lend'
                        : input.product.ownerName,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColor.fromHex('#30578F'),
                    ),
                  ),
                ),
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              child: _signatureBox(
                title: 'Semnatura locatar',
                child: signatureImage == null
                    ? pw.Center(child: pw.Text('Nesemnat'))
                    : pw.Center(
                        child: pw.Image(
                          signatureImage,
                          fit: pw.BoxFit.contain,
                          height: 74,
                        ),
                      ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 18),
        pw.Text(
          'Generat automat de Lend la ${_formatDate(DateTime.now())}.',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    ),
  );

  return document.save();
}

pw.Widget _infoGrid(List<(String, String)> rows) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColor.fromHex('#D7DAE2')),
    columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1.8)},
    children: [
      for (final row in rows)
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                row.$1,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(row.$2),
            ),
          ],
        ),
    ],
  );
}

pw.Widget _section(String title, String body) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 16),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Text(body, style: const pw.TextStyle(fontSize: 11, lineSpacing: 3)),
      ],
    ),
  );
}

pw.Widget _signatureBox({required String title, required pw.Widget child}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 8),
      pw.Container(
        height: 96,
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColor.fromHex('#C3C6D1')),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: child,
      ),
      pw.SizedBox(height: 6),
      pw.Container(height: 1, color: PdfColor.fromHex('#C3C6D1')),
    ],
  );
}

Future<Uint8List?> _signatureToPng(List<ui.Offset?> points) async {
  final actualPoints = points.whereType<ui.Offset>().toList();
  if (actualPoints.isEmpty) {
    return null;
  }

  const width = 900.0;
  const height = 300.0;
  const padding = 28.0;
  final maxX = actualPoints.map((point) => point.dx).reduce(math.max);
  final maxY = actualPoints.map((point) => point.dy).reduce(math.max);
  final scaleX = (width - padding * 2) / math.max(maxX, 1);
  final scaleY = (height - padding * 2) / math.max(maxY, 1);
  final scale = math.min(scaleX, scaleY);

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final background = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
  canvas.drawRect(
    const ui.Offset(0, 0) & const ui.Size(width, height),
    background,
  );

  final paint = ui.Paint()
    ..color = const ui.Color(0xFF30578F)
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round
    ..strokeWidth = 7;

  ui.Offset transform(ui.Offset point) {
    return ui.Offset(padding + point.dx * scale, padding + point.dy * scale);
  }

  for (var i = 0; i < points.length - 1; i++) {
    final current = points[i];
    final next = points[i + 1];
    if (current != null && next != null) {
      canvas.drawLine(transform(current), transform(next), paint);
    }
  }

  final picture = recorder.endRecording();
  final image = await picture.toImage(width.toInt(), height.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data?.buffer.asUint8List();
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.year}';
}
