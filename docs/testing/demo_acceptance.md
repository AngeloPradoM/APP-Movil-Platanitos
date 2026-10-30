# Matriz de aceptación de la demo frontend

Esta guía valida la demostración local sin iniciar NestJS ni PostgreSQL. En Android los datos se conservan en SQLite; en web permanecen durante la sesión abierta.

## Recorrido principal

| Orden | Perfil | Acción | Resultado esperado |
| :---: | :--- | :--- | :--- |
| 1 | Cliente | Agregar una variante disponible a la bolsa y completar el pago con Yape/Plin | Se crea un pedido con pago simulado, se vacía la bolsa y se reserva el stock |
| 2 | Almacén | Abrir **Preparación**, iniciar, marcar listo y despachar | Se descuenta el stock físico reservado y se asigna una entrega |
| 3 | Repartidor | Confirmar recojo, iniciar ruta, registrar nombre, firma y fotografía, y confirmar entrega | El pedido termina como entregado y conserva una constancia digital local |
| 4 | Cliente | Registrar un cambio, devolución o reclamo sobre el pedido | La solicitud aparece con estado Registrado |
| 5 | Atención al cliente | Atender y resolver la solicitud | El caso avanza a En revisión y luego a Resuelto |
| 6 | Administrador | Actualizar el panel | Los indicadores reflejan pedidos, entregas, ventas simuladas, stock y casos |
| 7 | Trabajador de tienda | Crear una reserva y confirmar recojo o cancelación | El stock se reserva y luego se descuenta o libera según la acción |

## Casos de control

- La tarjeta de demostración muestra un error y conserva intacta la bolsa.
- No se permite comprar o reservar más unidades que el stock disponible.
- Un pedido no puede despacharse antes de estar preparado.
- Los estados de reparto y atención solo avanzan en el orden permitido.
- Una entrega en camino exige nombre de quien recibe, firma y fotografía antes de completarse.
- Repetir un despacho, una entrega o el cierre de una reserva no duplica descuentos.
- En 320 px y con texto al 140 %, los cinco paneles de trabajadores no presentan desbordamientos.
- Ninguna pantalla solicita credenciales reales ni procesa dinero.

## Verificación automática

Desde la raíz del proyecto:

```powershell
flutter analyze
flutter test
flutter build web --release
flutter build apk --debug
```

El APK resultante se genera en `build/app/outputs/flutter-apk/app-debug.apk` y la versión web en `build/web/`.

## Reiniciar los datos locales

En Android, desinstala la aplicación del emulador o elimina sus datos desde **Ajustes → Aplicaciones → Platanitos → Almacenamiento → Borrar datos**. En Chrome basta con cerrar y volver a iniciar la aplicación, porque el adaptador web usa memoria temporal.
