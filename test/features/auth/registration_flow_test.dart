import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:platanitos_app/app/app.dart';
import 'package:platanitos_app/app/shop_shell.dart';
import 'package:platanitos_app/core/network/api_client.dart';
import 'package:platanitos_app/features/auth/data/auth_repository.dart';
import 'package:platanitos_app/app/state/shop_state.dart';
import 'package:platanitos_app/app/models/shop_models.dart';

void main() {
  for (final duplicate in [false, true]) {
    testWidgets(
      duplicate
          ? 'duplicate registration stays on form with useful feedback'
          : 'registration validates consent and enters shop as applicant',
      (tester) async {
        FlutterSecureStorage.setMockInitialValues({});
        tester.view.physicalSize = const Size(430, 950);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var requests = 0;
        final client = MockClient((request) async {
          requests++;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(request.url.path, '/auth/register');
          expect(body.containsKey('role'), isFalse);
          expect(body['name'], 'Postulante Prueba');
          expect(body['phone'], '+541123456789');
          return http.Response(
            jsonEncode(
              duplicate
                  ? {'message': 'Account exists'}
                  : {
                      'accessToken': 'test-access',
                      'refreshToken': 'test-refresh',
                      'user': {
                        'name': body['name'],
                        'email': body['email'],
                        'phone': body['phone'],
                        'role': 'POSTULANTE',
                      },
                    },
            ),
            duplicate ? 409 : 201,
            headers: {'content-type': 'application/json'},
          );
        });
        final state = ShopState(
          authRepository: AuthRepository(
            client: ApiClient(baseUrl: 'http://test', client: client),
          ),
        );
        addTearDown(state.dispose);
        await tester.pumpWidget(PlatanitosApp(state: state));
        await tester.ensureVisible(
          find.textContaining('Reg', findRichText: true),
        );
        await tester.tap(find.textContaining('Reg', findRichText: true));
        await tester.pumpAndSettle();
        expect(find.text('Nombres'), findsWidgets);
        expect(find.text('Apellidos'), findsWidgets);
        await tester.ensureVisible(find.text('PE +51'));
        await tester.tap(find.text('PE +51'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('AR +54').last);
        await tester.pumpAndSettle();
        final fields = find.byType(TextFormField);
        final values = [
          'Postulante',
          'Prueba',
          '00000000',
          'nuevo@example.com',
          '1123456789',
          'UnaClave-Test-123',
        ];
        for (var i = 0; i < values.length; i++) {
          await tester.ensureVisible(fields.at(i));
          await tester.enterText(fields.at(i), values[i]);
        }
        final button = find.widgetWithText(FilledButton, 'Crear Cuenta');
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pump();
        expect(requests, 0);
        await tester.ensureVisible(find.byType(Checkbox));
        await tester.tap(find.byType(Checkbox));
        await tester.pump();
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(requests, 1);
        expect(state.signedIn, !duplicate);
        if (duplicate) {
          expect(
            find.text(
              'Este correo ya tiene una cuenta. Inicia sesión o usa otro correo.',
            ),
            findsOneWidget,
          );
        } else {
          expect(state.user.role, UserRole.postulante);
          expect(find.byType(ShopShell), findsOneWidget);
        }
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
