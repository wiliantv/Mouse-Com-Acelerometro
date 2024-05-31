import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sensors/sensors.dart';
import 'package:wakelock/wakelock.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ServerAddressScreen(),
    );
  }
}

class ServerAddressScreen extends StatefulWidget {
  @override
  _ServerAddressScreenState createState() => _ServerAddressScreenState();
}

class _ServerAddressScreenState extends State<ServerAddressScreen> {
  final TextEditingController _controller = TextEditingController();

  initState() {
    super.initState();
    _controller.text = '192.168.10.125';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter Server Address'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Server Address',
                hintText: 'Enter server address (e.g., 192.168.2.114)',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SensorDataSender(
                      serverAddress: _controller.text,
                    ),
                  ),
                );
              },
              child: Text('Connect'),
            ),
          ],
        ),
      ),
    );
  }
}

class SensorDataSender extends StatefulWidget {
  final String serverAddress;

  SensorDataSender({required this.serverAddress});

  @override
  _SensorDataSenderState createState() => _SensorDataSenderState();
}

class _SensorDataSenderState extends State<SensorDataSender> {
  late WebSocketChannel? _channel;

  double _lastAx = 0;
  double _lastAy = 0;
  bool _mouseEnabled = false;

  @override
  void initState() {
    super.initState();
    _connectToServer();
  }

  void _connectToServer() {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://${widget.serverAddress}:8080/ws/sensorData'),
    );

    _channel!.stream.listen((message) {
      // Handle any incoming messages from the server
    }, onError: (error) {
      // If there is an error with the connection, return to the server address screen
      Navigator.pop(context);
    });

    Wakelock.enable();
    double filterFactor = 0.15;
    accelerometerEvents.listen((AccelerometerEvent event) {
      if (_mouseEnabled && _channel != null) {
        // Vai de -10 a 10 preciso sanitizar isso para -1000 a 1000
        double xis = event.x * 20;
        double ypesolon = event.y * 20;

        final ax = (_lastAx * (1 - filterFactor)) + (xis * filterFactor);
        final ay = (_lastAy * (1 - filterFactor)) + (ypesolon * filterFactor);

        _lastAx = ax;
        _lastAy = ay;

        // Ajustar o movimento e adicionar uma área neutra
        double threshold = 0.5; // Defina o tamanho da área neutra
        double thresholdy = 0.5; // Defina o tamanho da área neutra
        double sensitivity = 0.5; // Ajuste a sensibilidade do movimento

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
        _channel!.sink.add(data);
      }
    });
  }

  void _sendClick(String button) {
    if (_channel != null) {
      final data = jsonEncode({
        'type': 'click',
        'button': button,
      });
      _channel!.sink.add(data);
    }
  }

  @override
  void dispose() {
    Wakelock.disable();
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mouse Control'),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              _channel?.sink.close();
              Navigator.pop(context); // Retorna para a tela de configuração
            },
          ),
        ],
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
