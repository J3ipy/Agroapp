import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

// Este handler precisa ser uma função top-level (fora de qualquer classe)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Mensagem recebida em background: ${message.messageId}");
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 1. Pedir permissão ao usuário (obrigatório no Android 13+ e iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Permissão de notificação: ${settings.authorizationStatus}');

    // 2. Configurar o plugin de notificações locais (ícone padrão do Android)
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(initializationSettings);

    // 3. Ouvir mensagens quando o app estiver aberto (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'agroapp_channel',
            'Notificações AgroApp',
            channelDescription: 'Canal principal de pedidos e alertas',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  }

  // Função para simular o recebimento ao finalizar a compra
  Future<void> sendOrderConfirmationLocal(String pedidoId) async {
    await _localNotifications.show(
      0,
      'Pedido Confirmado! 🥬',
      'Seu pedido foi recebido e está aguardando o pagamento.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'agroapp_channel',
          'Notificações AgroApp',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}