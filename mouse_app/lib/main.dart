import 'package:flutter/material.dart';
import 'package:sensors/sensors.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:wakelock/wakelock.dart';
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SensorDataSender(),
    );
  }
}

class SensorDataSender extends StatefulWidget {
  @override
  _SensorDataSenderState createState() => _SensorDataSenderState();
}

class _SensorDataSenderState extends State<SensorDataSender> {
  final channel = WebSocketChannel.connect(
    Uri.parse('ws://192.168.2.114:8080/ws/sensorData'), // Substitua pelo endereço IP do seu servidor
  );

  double _lastAx = 0;
  double _lastAy = 0;
  bool _mouseEnabled = false;

  @override
  void initState() {
    super.initState();
    Wakelock.enable();  // Ativar o wakelock para manter a tela ligada

    accelerometerEvents.listen((AccelerometerEvent event) {
      if (_mouseEnabled) {
        final ax = (_lastAx * 0.9) + (event.x * 0.1);
        final ay = (_lastAy * 0.9) + (event.y * 0.1);

        _lastAx = ax;
        _lastAy = ay;

        // Ajustar o movimento e adicionar uma área neutra
        double threshold = 1; // Defina o tamanho da área neutra
        double thresholdy = 0.5; // Defina o tamanho da área neutra
        double sensitivity = 4.0; // Ajuste a sensibilidade do movimento

        double dx = 0;
        double dy = 0;

        if (ax.abs() > threshold) {
          dx = (ax.abs() - threshold) * sensitivity * (ax > 0 ? -1 : 1);
        }
        if (ay.abs() > thresholdy) {
          dy = (ay.abs() - thresholdy) * sensitivity * (ay > 0 ? -1 : 1);
        }

        final data = jsonEncode({
          'type': 'move',
          'dx': dx,
          'dy': dy,
        });
        channel.sink.add(data);
      }
    });
  }

  void _sendClick(String button) {
    final data = jsonEncode({
      'type': 'click',
      'button': button,
    });
    channel.sink.add(data);
  }

  @override
  void dispose() {
    Wakelock.disable();  // Desativar o wakelock quando o widget for destruído
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mouse Control'),
      ),
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Move your phone to control the mouse cursor.'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () => _sendClick('left'),
                    child: Text('Left Click'),
                  ),
                  ElevatedButton(
                    onPressed: () => _sendClick('right'),
                    child: Text('Right Click'),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  _mouseEnabled = !_mouseEnabled;
                });
              },
              child: Icon(_mouseEnabled ? Icons.mouse : Icons.mouse_outlined),
            ),
          ),
        ],
      ),
    );
  }
}
