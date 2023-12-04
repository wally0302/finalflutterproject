import 'dart:async';
import '../model/chat.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter/material.dart';
import '../services/notification_servicer.dart';

class StreamSocket {
  static final StreamController<Object> _socketResponse =
      StreamController<Object>();
  static Stream<Object> get getResponse => _socketResponse.stream;

  static final io.Socket _socket = io.io('http://163.22.17.145:3000',
      io.OptionBuilder().setTransports(['websocket']).build());

  static connectAndListen() async {
    print('CONNECT AND LISTEN');
    try {
      _socket.connect();
      _socket.onConnect((_) {
        print('============\nSOCKET 連線 成功\n============');
      });
      // 傳投票結果
      _socket.on('voteMessage', (data) {
        print('---------------------streamsocket---------------------');
        print(data);
        NotificationService().showNotificationAndroid('系統訊息', data.toString());
      });

      _socket.on('message', (data) {
        // print('收到訊息');
        // print(data);
        // _socketResponse.sink.add(Chat.fromRawJson(data));
        var message = [Chat.fromRawJson(data)];
        // print(message[0]);
        // _socketResponse.sink.add(message);

        NotificationService().showNotificationAndroid(
            '${message[0].userMall}', '${message[0].messageContent}');
      });
    } catch (error) {
      print('ERROR :\n$error');
    }
  }
}
