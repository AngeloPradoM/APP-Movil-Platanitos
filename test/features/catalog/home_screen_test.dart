import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platanitos_app/app/app.dart';
import 'package:platanitos_app/app/data/demo_data.dart';
import 'package:platanitos_app/app/state/shop_state.dart';
import 'package:platanitos_app/core/theme/app_theme.dart';
import 'package:platanitos_app/features/catalog/presentation/screens/catalog_screens.dart';

Future<ShopState> _mountShop(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final state = ShopState()..login();
  addTearDown(state.dispose);
  await tester.pumpWidget(PlatanitosApp(state: state));
  await tester.pump();
  return state;
}

Finder get _homeScroll => find.byType(Scrollable).first;

void main() {
  testWidgets('la portada se desplaza hasta Novedades y el pie', (
    tester,
  ) async {
    await _mountShop(tester);
    expect(find.text('Recomendados para ti'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Novedades'),
      300,
      scrollable: _homeScroll,
    );
    expect(find.text('Novedades'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('© Platanitos · Demo académica sin fines comerciales'),
      300,
      scrollable: _homeScroll,
    );
    expect(find.text('Atención al cliente'), findsOneWidget);
    expect(find.text('Ver todo el catálogo'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('con los productos de respaldo se ocultan las secciones vacías', (
    tester,
  ) async {
    await _mountShop(tester);
    expect(find.text('Zapatillas'), findsWidgets);
    expect(find.text('Botines'), findsWidgets);
    expect(find.text('Running'), findsWidgets);
    final seen = <String>{};
    const titles = [
      'Ofertas Cyber',
      'Compra por marca',
      'Para toda la familia',
      'Zapatillas más buscadas',
      'Novedades',
    ];
    while (find.text('Atención al cliente').evaluate().isEmpty) {
      seen.addAll(
        titles.where((title) => find.text(title).evaluate().isNotEmpty),
      );
      await tester.drag(_homeScroll, const Offset(0, -250));
      await tester.pump();
    }
    expect(seen, containsAll(['Ofertas Cyber', 'Compra por marca', 'Novedades']));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tocar un círculo de categoría abre esa categoría', (
    tester,
  ) async {
    final state = await _mountShop(tester);
    await tester.tap(find.text('Botines'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(CategoryScreen), findsOneWidget);
    expect(state.catalog.narrows, isFalse);
    final botinesCount =
        products.where((product) => product.category == 'Botines').length;
    expect(
      find.text(
        botinesCount == 1 ? '1 producto' : '$botinesCount productos',
      ),
      findsOneWidget,
    );
    expect(find.text('Botines Chelsea Abril'), findsOneWidget);
    expect(find.text('Tacos Amelia'), findsNothing);

    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(CategoryScreen), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'una colección sin categorías filtra el listado y se puede quitar',
    (tester) async {
      final state = await _mountShop(tester);
      await tester.tap(find.text('Ver todo').first);
      await tester.pump();
      expect(state.catalog.collection?.label, 'Calzado');
      expect(find.text('Volver a categorías'), findsOneWidget);
      expect(find.text('Tacos Amelia'), findsOneWidget);

      await tester.tap(find.byTooltip('Quitar filtro Calzado'));
      await tester.pump();
      expect(state.catalog.collection, isNull);
      expect(find.text('Todas las categorías'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('tocar una marca abre el catálogo filtrado por esa marca', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final state = await _mountShop(tester);
    final brand = find.bySemanticsLabel('Ver productos de NIKE');
    await tester.scrollUntilVisible(brand, 300, scrollable: _homeScroll);
    await tester.tap(brand);
    await tester.pump();
    expect(state.catalog.brands, {'NIKE'});
    expect(state.catalog.query, isEmpty);
    expect(find.text('Volver a categorías'), findsOneWidget);
    expect(find.text('Zapatilla Running Air Flow'), findsOneWidget);
    expect(find.text('Zapatilla Plataforma'), findsNothing);
    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('el banner avanza solo y se detiene si se reducen animaciones', (
    tester,
  ) async {
    for (final reduceMotion in [false, true]) {
      final state = ShopState();
      addTearDown(state.dispose);
      await tester.pumpWidget(
        ShopScope(
          state: state,
          child: MaterialApp(
            theme: buildTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(disableAnimations: reduceMotion),
              child: child!,
            ),
            home: Scaffold(body: HomeScreen(onCatalog: () {})),
          ),
        ),
      );
      final controller = tester
          .widget<PageView>(find.byType(PageView))
          .controller!;
      final start = controller.page!;
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 600));
      expect(controller.page, reduceMotion ? start : start + 1);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
