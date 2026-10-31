import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Lectura en voz alta para avisos críticos (p. ej. confirmar pago).
abstract final class ShopSpeech {
  static final FlutterTts _tts = FlutterTts();
  static bool _ready = false;

  /// Nombres cercanos a voz natural / tipo asistente (no existe “Siri” fuera de Apple).
  static const _preferredVoices = [
    'siri',
    'monica',
    'mónica',
    'paulina',
    'sabina',
    'helena',
    'elvira',
    'lucía',
    'lucia',
    'google español',
    'google spanish',
    'microsoft sabina',
    'microsoft helena',
  ];

  static Future<void> _ensureReady() async {
    if (_ready) return;
    try {
      await _tts.setLanguage('es-MX');
      await _tts.setSpeechRate(kIsWeb ? 0.92 : 0.45);
      await _tts.setVolume(1);
      await _tts.setPitch(1.05);
      if (!kIsWeb) {
        await _tts.awaitSpeakCompletion(false);
      }
      await _preferNaturalSpanishVoice();
      _ready = true;
    } catch (_) {
      // Sin motor TTS: solo queda el anuncio semántico.
    }
  }

  static Future<void> _preferNaturalSpanishVoice() async {
    try {
      final raw = await _tts.getVoices;
      if (raw is! List) return;
      final voices = <Map<String, String>>[
        for (final item in raw)
          if (item is Map)
            {
              for (final entry in item.entries)
                '${entry.key}': '${entry.value}',
            },
      ];
      if (voices.isEmpty) return;

      Map<String, String>? pick;
      for (final needle in _preferredVoices) {
        for (final voice in voices) {
          final name = (voice['name'] ?? voice['voiceName'] ?? '').toLowerCase();
          final locale = (voice['locale'] ?? voice['localeId'] ?? '')
              .toLowerCase();
          final isSpanish =
              locale.startsWith('es') ||
              name.contains('spanish') ||
              name.contains('español') ||
              name.contains('espanol');
          if (isSpanish && name.contains(needle)) {
            pick = voice;
            break;
          }
        }
        if (pick != null) break;
      }
      if (pick == null) {
        for (final voice in voices) {
          final locale = (voice['locale'] ?? voice['localeId'] ?? '')
              .toLowerCase();
          if (locale.startsWith('es')) {
            pick = voice;
            break;
          }
        }
      }

      if (pick == null) return;
      await _tts.setVoice({
        'name': pick['name'] ?? pick['voiceName'] ?? '',
        'locale': pick['locale'] ?? pick['localeId'] ?? 'es-MX',
      });
    } catch (_) {}
  }

  /// Monto hablable: `606.70` → `606 con 70`.
  static String speakableAmount(double total) {
    final parts = total.toStringAsFixed(2).split('.');
    return '${parts[0]} con ${parts[1]}';
  }

  /// Frase fija del modal de pago.
  static String paymentPrompt(double total) =>
      'Su monto a pagar es de ${speakableAmount(total)} soles, '
      'presione el botón de confirmar para realizar su pago.';

  /// Habla [message] y lo anuncia al lector de pantalla.
  static Future<void> announce(String message) async {
    final text = message.trim();
    if (text.isEmpty) return;
    final view =
        PlatformDispatcher.instance.implicitView ??
        PlatformDispatcher.instance.views.firstOrNull;
    if (view != null) {
      await SemanticsService.sendAnnouncement(
        view,
        text,
        TextDirection.ltr,
        assertiveness: Assertiveness.assertive,
      );
    }
    try {
      await _ensureReady();
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      // Silencio si el dispositivo no permite síntesis.
    }
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
