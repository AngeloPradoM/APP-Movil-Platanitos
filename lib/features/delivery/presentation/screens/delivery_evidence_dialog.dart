import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../operations/domain/operations_models.dart';

class DeliveryEvidenceInput {
  const DeliveryEvidenceInput({
    required this.recipientName,
    required this.signatureData,
    required this.photoBytes,
  });

  final String recipientName;
  final String signatureData;
  final Uint8List photoBytes;
}

Future<DeliveryEvidenceInput?> showDeliveryEvidenceForm(BuildContext context) =>
    showDialog<DeliveryEvidenceInput>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DeliveryEvidenceDialog(),
    );

Future<void> showDeliveryEvidenceDetails(
  BuildContext context,
  DeliveryEvidence evidence,
) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Constancia de entrega'),
    content: SizedBox(
      width: 460,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline),
              title: Text(evidence.recipientName),
              subtitle: Text(
                'Recibido el ${evidence.capturedAt.day}/${evidence.capturedAt.month}/${evidence.capturedAt.year}',
              ),
            ),
            const Text('Firma digital'),
            const SizedBox(height: 6),
            DeliverySignaturePreview(data: evidence.signatureData),
            const SizedBox(height: 16),
            const Text('Fotografía de evidencia'),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                evidence.photoBytes,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      FilledButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cerrar'),
      ),
    ],
  ),
);

class _DeliveryEvidenceDialog extends StatefulWidget {
  const _DeliveryEvidenceDialog();

  @override
  State<_DeliveryEvidenceDialog> createState() =>
      _DeliveryEvidenceDialogState();
}

class _DeliveryEvidenceDialogState extends State<_DeliveryEvidenceDialog> {
  final recipient = TextEditingController();
  final strokes = <List<Offset>>[];
  final picker = ImagePicker();
  Uint8List? photoBytes;
  bool loadingPhoto = false;
  String? photoError;

  @override
  void initState() {
    super.initState();
    _recoverLostPhoto();
  }

  Future<void> _recoverLostPhoto() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final response = await picker.retrieveLostData();
      final files = response.files;
      if (!mounted || response.isEmpty || files == null || files.isEmpty) {
        return;
      }
      final bytes = await files.last.readAsBytes();
      if (mounted) {
        setState(() {
          photoBytes = bytes;
          photoError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          photoError = 'No se pudo recuperar la fotografÃ­a anterior.';
        });
      }
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() {
      loadingPhoto = true;
      photoError = null;
    });
    try {
      final photo = await picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 70,
        requestFullMetadata: false,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        if (mounted) setState(() => photoBytes = bytes);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          photoError = 'No se pudo abrir la cámara. Puedes elegir una imagen.';
        });
      }
    } finally {
      if (mounted) setState(() => loadingPhoto = false);
    }
  }

  String _signatureData() => jsonEncode([
    for (final stroke in strokes)
      [
        for (final point in stroke) [point.dx, point.dy],
      ],
  ]);

  bool get _hasMeaningfulSignature {
    var distance = 0.0;
    for (final stroke in strokes) {
      for (var index = 1; index < stroke.length; index++) {
        distance += (stroke[index] - stroke[index - 1]).distance;
      }
    }
    return distance >= 24;
  }

  void _confirm() {
    if (recipient.text.trim().isEmpty ||
        !_hasMeaningfulSignature ||
        photoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa el nombre, la firma y la fotografía.'),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      DeliveryEvidenceInput(
        recipientName: recipient.text.trim(),
        signatureData: _signatureData(),
        photoBytes: photoBytes!,
      ),
    );
  }

  @override
  void dispose() {
    recipient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Confirmar entrega'),
    content: SizedBox(
      width: 460,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Registra quién recibe el pedido. La constancia queda guardada con el envío.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: recipient,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre de quien recibe',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Firma digital',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton.icon(
                  onPressed: strokes.isEmpty
                      ? null
                      : () => setState(strokes.clear),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Limpiar'),
                ),
              ],
            ),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) => setState(() {
                  strokes.add([details.localPosition]);
                }),
                onPanUpdate: (details) => setState(() {
                  strokes.last.add(details.localPosition);
                }),
                child: CustomPaint(
                  painter: _SignaturePainter(strokes),
                  child: strokes.isEmpty
                      ? const Center(
                          child: Text(
                            'Firma aquí',
                            style: TextStyle(color: Colors.black45),
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (photoBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  photoBytes!,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
            if (photoError != null) ...[
              const SizedBox(height: 8),
              Text(photoError!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: loadingPhoto
                      ? null
                      : () => _pickPhoto(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Tomar fotografía'),
                ),
                OutlinedButton.icon(
                  onPressed: loadingPhoto
                      ? null
                      : () => _pickPhoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Elegir imagen'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton.icon(
        onPressed: _confirm,
        icon: const Icon(Icons.verified_outlined),
        label: const Text('Confirmar entrega'),
      ),
    ],
  );
}

class DeliverySignaturePreview extends StatelessWidget {
  const DeliverySignaturePreview({super.key, required this.data});
  final String data;

  @override
  Widget build(BuildContext context) {
    final strokes = _decodeSignature(data);
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _SignaturePainter(strokes),
        child: strokes.isEmpty
            ? const Center(child: Text('Firma no disponible'))
            : null,
      ),
    );
  }
}

List<List<Offset>> _decodeSignature(String data) {
  try {
    final decoded = jsonDecode(data) as List<dynamic>;
    return [
      for (final stroke in decoded)
        [
          for (final point in stroke as List<dynamic>)
            if (point is List<dynamic> &&
                point.length >= 2 &&
                point[0] is num &&
                point[1] is num)
              Offset(
                (point[0] as num).toDouble(),
                (point[1] as num).toDouble(),
              ),
        ],
    ].where((stroke) => stroke.length >= 2).toList(growable: false);
  } catch (_) {
    return const [];
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter(this.strokes);
  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF17221B)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) => true;
}
