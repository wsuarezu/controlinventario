import 'package:controlinventario/utils/reporte_errores.dart';
import 'package:controlinventario/widgets/error_pantalla_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReporteErrores.limpiar', () {
    test('oculta la cabecera Bearer', () {
      expect(
        ReporteErrores.limpiar('Authorization: Bearer abc.def-123'),
        'Authorization: Bearer ***',
      );
    });

    test('oculta un JWT suelto', () {
      const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.firma_123';
      expect(ReporteErrores.limpiar('token=$jwt fin'), 'token=*** fin');
    });

    test('oculta contraseñas en formularios', () {
      expect(
        ReporteErrores.limpiar('username=a@b.com&password=secreta123'),
        'username=a@b.com&password=***',
      );
    });
  });

  test('registrar guarda el mensaje ya limpio', () {
    ReporteErrores.recientes.clear();
    ReporteErrores.registrar(StateError('falló con Bearer xyz'), null);
    expect(ReporteErrores.recientes.single, contains('Bearer ***'));
    expect(ReporteErrores.recientes.single, isNot(contains('xyz')));
  });

  testWidgets('ErrorPantallaView reemplaza la pantalla roja con un mensaje amable', (tester) async {
    await tester.pumpWidget(const ErrorPantallaView());
    expect(find.text('Esta pantalla tuvo un problema'), findsOneWidget);
    expect(find.byType(Scaffold), findsNothing);
  });
}
