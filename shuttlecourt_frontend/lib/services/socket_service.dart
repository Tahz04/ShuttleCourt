import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shuttlecourt/config/api_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  IO.Socket? _socket;

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  void connect() {
    if (_socket != null && _socket!.connected) return;

    // Remove /api from baseUrl to get the host URL for socket
    String socketUrl = ApiConfig.baseUrl.replaceAll('/api', '');

    _socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();
    
    _socket!.onConnect((_) {
      print('🔗 Socket.IO connected');
    });

    _socket!.onDisconnect((_) {
      print('🔌 Socket.IO disconnected');
    });
  }

  void joinCourt(String courtName) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join_court', courtName);
    }
  }

  void onBookingUpdated(Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.on('booking_updated', callback);
    }
  }

  void offBookingUpdated() {
    if (_socket != null) {
      _socket!.off('booking_updated');
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }
  }
}
