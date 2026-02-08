import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/serial_service.dart';

class MapNfcScreen extends StatefulWidget {
  const MapNfcScreen({super.key});

  @override
  State<MapNfcScreen> createState() => _MapNfcScreenState();
}

class _MapNfcScreenState extends State<MapNfcScreen> {
  final SerialService _serialService = SerialService();
  final TextEditingController _studentIdController = TextEditingController();

  String? _selectedPort;
  List<String> _ports = [];
  String _scannedUid = '';
  String? _statusMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPorts();

    // Listen to serial data
    _serialService.dataStream.listen((data) {
      final cleanData = data.trim();
      if (cleanData.isEmpty || cleanData.contains("Arduino Ready")) return;

      setState(() {
        // Support both "UID: XY..." format and raw "XY..." format
        _scannedUid = cleanData.replaceAll('UID:', '').trim();
        _statusMessage = 'Card Scanned: $_scannedUid';
      });
    });
  }

  @override
  void dispose() {
    _serialService.disconnect();
    _studentIdController.dispose();
    super.dispose();
  }

  void _loadPorts() {
    setState(() {
      _ports = _serialService.getAvailablePorts();
      if (_ports.isNotEmpty) {
        _selectedPort = _ports.first;
      }
    });
  }

  void _connectPort() {
    if (_selectedPort == null) return;

    if (_serialService.isConnected) {
      _serialService.disconnect();
      setState(() => _statusMessage = 'Disconnected');
    } else {
      bool success = _serialService.connect(_selectedPort!);
      setState(() {
        _statusMessage = success
            ? 'Connected to $_selectedPort'
            : 'Connection Failed';
      });
    }
  }

  Future<void> _mapCardToStudent() async {
    if (_scannedUid.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please scan a card first')));
      return;
    }

    if (_studentIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Student ID')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final studentId = _studentIdController.text.trim();

      // Check if student exists
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw 'Student ID not found';
      }

      final userDoc = userQuery.docs.first;

      // Update User with NFC UID
      await userDoc.reference.update({'nfcUid': _scannedUid});

      setState(() {
        _statusMessage = 'Success! Card mapped to $studentId';
        _scannedUid = '';
        _studentIdController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Card Mapped Successfully!'),
        ),
      );
    } catch (e) {
      setState(() => _statusMessage = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map NFC Card')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Port Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Icon(Icons.usb),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedPort,
                        hint: const Text('Select Port'),
                        items: _ports
                            .map(
                              (p) => DropdownMenuItem(value: p, child: Text(p)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedPort = v),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadPorts,
                    ),
                    ElevatedButton(
                      onPressed: _connectPort,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _serialService.isConnected
                            ? Colors.red
                            : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _serialService.isConnected ? 'Disconnect' : 'Connect',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Status Area
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  const Text(
                    'Scanned NFC UID',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _scannedUid.isEmpty ? 'Waiting for card...' : _scannedUid,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Student ID Input
            TextField(
              controller: _studentIdController,
              decoration: const InputDecoration(
                labelText: 'Student ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 20),

            if (_statusMessage != null)
              Text(
                _statusMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _statusMessage!.startsWith('Error')
                      ? Colors.red
                      : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const Spacer(),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _mapCardToStudent,
              icon: const Icon(Icons.link),
              label: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Map Card to Student'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
