import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:frosthub/services/notification_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  late IO.Socket socket;

  SocketService._internal();

  void initSocket(String userId) {
    socket = IO.io('https://frostcore.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('🔌 Connected to socket');
      socket.emit('register', userId); // Join personal room for notifications
    });

    socket.on('notification', (data) {
      print('🔔 Received backend notification: $data');

      final title = data['title'] ?? 'New Notification';
      final body = data['body'] ?? '';
      NotificationService.showAnnouncementNotification(
        title: title,
        body: body,
      );
    });

    socket.on('new-message', (data) {
      print('💬 New group message: $data');
      // You can handle group chat updates here if needed
    });

    socket.onDisconnect((_) => print('❌ Socket disconnected'));
  }

  void joinGroup(String groupId) {
    socket.emit('join-group', groupId);
  }

  void sendMessage(String groupId, Map<String, dynamic> message) {
    socket.emit('new-message', message);
  }

  void onNewMessage(Function(dynamic) callback) {
    socket.on('new-message', callback);
  }

  void dispose() {
    socket.dispose();
  }
}
