import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  if (kDebugMode) {
    print(
        'Handling a background message: ${message.messageId}, data: ${message.notification?.title} , xd:: ${message.notification?.body}');
  }
  // Aquí puedes manejar la recepción de mensajes en segundo plano.
}

class FirebaseApi {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // Obtener el token de FCM (útil para probar el envío de mensajes directamente al dispositivo).
    final String? fcmToken = await _firebaseMessaging.getToken();
    if (kDebugMode) {
      print('FCM Token: $fcmToken');
    }

    // Configurar el manejador de mensajes en segundo plano.
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

    // Manejar mensajes en primer plano.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print(
            'Received a message in foreground: ${message.messageId}, data: ${message.data}');
        print(
            "Mensaje recibido: ${message.notification?.title}, ${message.notification?.body}");
      }
      // Aquí puedes mostrar una notificación o realizar otras acciones con el mensaje.
    });

    // Manejar cuando el usuario hace clic en la notificación y la aplicación se abre desde un estado terminado.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print(
            'Received a message with the app closed: ${message.messageId}, data: ${message.data}');
      }
      // Aquí puedes navegar a una pantalla específica en tu aplicación.
    });
  }
}
