import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_libserialport/flutter_libserialport.dart';

class SerialService {
  SerialPort? _port;
  final StreamController<String> _dataController =
      StreamController<String>.broadcast();
  bool _isListening = false;
  String _buffer = '';

  Stream<String> get dataStream => _dataController.stream;
  bool get isConnected => _port != null && _port!.isOpen;

  // Get list of available ports
  List<String> getAvailablePorts() {
    return SerialPort.availablePorts;
  }

  // Connect to a specific port
  bool connect(String address) {
    try {
      if (_port != null) {
        disconnect();
      }

      final port = SerialPort(address);
      if (!port.openReadWrite()) {
        print('Failed to open port $address');
        return false;
      }

      _port = port;

      // Configure port
      final config = SerialPortConfig();
      config.baudRate = 9600;
      config.bits = 8;
      config.stopBits = 1;
      config.parity = SerialPortParity.none;
      port.config = config;

      _startListening();
      return true;
    } catch (e) {
      print('Error connecting to port: $e');
      return false;
    }
  }

  void disconnect() {
    if (_port != null) {
      if (_port!.isOpen) _port!.close();
      _port!.dispose();
      _port = null;
    }
    _isListening = false;
  }

  void _startListening() {
    if (_port == null || _isListening) return;
    _isListening = true;

    final reader = SerialPortReader(_port!);
    reader.stream.listen(
      (Uint8List data) {
        // Convert bytes to string
        final String chunk = String.fromCharCodes(data);
        print('SerialService Raw Data: $chunk'); // DEBUG PRINT
        _buffer += chunk;

        // Process complete lines
        while (_buffer.contains('\n')) {
          final int index = _buffer.indexOf('\n');
          final String line = _buffer.substring(0, index).trim();
          _buffer = _buffer.substring(index + 1);

          if (line.isNotEmpty) {
            _dataController.add(line);
          }
        }
      },
      onError: (e) {
        print('Serial read error: $e');
        disconnect();
      },
      onDone: () {
        _isListening = false;
      },
    );
  }
}
