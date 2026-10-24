import 'package:controlinventario/main.dart';
import 'package:controlinventario/widgets/empty_view.dart';
import 'package:controlinventario/widgets/error_view.dart';
import 'package:controlinventario/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _envolver(Widget hijo) => InventarioApp(home: Scaffold(body: hijo));

void main() {
  testWidgets('la app arranca con su título', (tester) async {
    await tester.pumpWidget(const InventarioApp());
    expect(find.text('Control de Inventario'), findsOneWidget);
  });

  testWidgets('LoadingView muestra indicador y mensaje', (tester) async {
    await tester.pumpWidget(_envolver(const LoadingView(mensaje: 'Cargando productos...')));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Cargando productos...'), findsOneWidget);
  });

  testWidgets('EmptyView ofrece una acción para no ser un callejón sin salida', (tester) async {
    var pulsado = false;
    await tester.pumpWidget(
      _envolver(
        EmptyView(
          mensaje: 'Aún no tienes productos',
          textoAccion: 'Agregar producto',
          onAccion: () => pulsado = true,
        ),
      ),
    );

    await tester.tap(find.text('Agregar producto'));
    expect(pulsado, isTrue);
  });

  testWidgets('ErrorView muestra el mensaje y permite reintentar', (tester) async {
    var reintentos = 0;
    await tester.pumpWidget(
      _envolver(
        ErrorView(mensaje: 'No hay conexión con el servidor.', onReintentar: () => reintentos++),
      ),
    );

    expect(find.text('No hay conexión con el servidor.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    expect(reintentos, 1);
  });
}
