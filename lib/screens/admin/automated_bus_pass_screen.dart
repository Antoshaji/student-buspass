import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../models/trip_model.dart';
import '../../models/bus_pass_request_model.dart';
import '../../services/serial_service.dart';
import 'package:intl/intl.dart';

class AutomatedBusPassScreen extends StatefulWidget {
  const AutomatedBusPassScreen({super.key});

  @override
  State<AutomatedBusPassScreen> createState() => _AutomatedBusPassScreenState();
}

class _AutomatedBusPassScreenState extends State<AutomatedBusPassScreen> {
  final SerialService _serialService = SerialService();
  String _tripType = 'From College';
  bool _isNfcMode = false;
  bool _isSearchMode = false;
  final _studentIdController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _receiptData;
  String? _errorMessage;

  // Serial Port State
  List<String> _ports = [];
  String? _selectedPort;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _loadPorts();

    // Listen to NFC scans
    _serialService.dataStream.listen((data) {
      // Only process NFC if in NFC Mode
      if (!_isNfcMode) return;

      final cleanData = data.trim();
      if (cleanData.isEmpty || cleanData.contains("Arduino Ready")) return;

      final uid = cleanData.replaceAll('UID:', '').trim();
      _processNfcScan(uid);
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

  void _toggleConnection() {
    if (_serialService.isConnected) {
      _serialService.disconnect();
      setState(() => _isScanning = false);
    } else {
      if (_selectedPort != null) {
        bool success = _serialService.connect(_selectedPort!);
        setState(() => _isScanning = success);
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to connect to port')),
          );
        }
      }
    }
  }

  Future<void> _processNfcScan(String nfcUid) async {
    if (_isLoading || _receiptData != null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('nfcUid', isEqualTo: nfcUid)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw 'Card not mapped to any student';
      }

      final userData = userQuery.docs.first.data();
      final studentId = userData['studentId'];

      if (studentId == null) throw 'Student ID missing for this user';

      await _processStudentId(studentId);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _processStudentId(String studentId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _receiptData = null;
    });

    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw 'Student ID not found';
      }

      final userDoc = userQuery.docs.first;
      final userData = userDoc.data();

      if (userData['bus_pass_status'] != 'approved') {
        throw 'Bus pass not active';
      }

      final passQuery = await FirebaseFirestore.instance
          .collection('bus_pass_requests')
          .where('studentId', isEqualTo: studentId)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get();

      if (passQuery.docs.isEmpty) throw 'Pass details not found';

      final passData = BusPassRequestModel.fromMap(passQuery.docs.first.data());
      final double tripCost = passData.cost;
      final double currentBalance = (userData['balance'] ?? 0.0).toDouble();

      if (currentBalance < tripCost) {
        throw 'Insufficient balance (Bal: ₹$currentBalance, Cost: ₹$tripCost)';
      }

      final newBalance = currentBalance - tripCost;
      await userDoc.reference.update({'balance': newBalance});

      final trip = TripModel(
        id: const Uuid().v4(),
        studentId: studentId,
        route: passData.routeName,
        stop: passData.stopName,
        cost: tripCost,
        remainingBalance: newBalance,
        timestamp: DateTime.now(),
        tripType: _tripType,
      );

      await FirebaseFirestore.instance
          .collection('trips')
          .doc(trip.id)
          .set(trip.toMap());

      setState(() {
        _receiptData = {
          'id': studentId,
          'name': userData['name'],
          'route': passData.routeName,
          'stop': passData.stopName,
          'time': DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
          'balance': newBalance,
          'cost': tripCost,
        };
        _studentIdController.clear();
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Automated Bus Pass'),
        actions: [_buildConnectionStatus()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTripTypeSelector(),
            const Divider(),
            const SizedBox(height: 20),

            // Content Switching
            if (_receiptData != null)
              _buildReceipt()
            else if (_isNfcMode)
              _buildNfcScanMode()
            else if (_isSearchMode)
              _buildSearchMode()
            else
              _buildMainMenu(),

            // Error Message
            if (_errorMessage != null && _receiptData == null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    if (_ports.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Icon(Icons.usb_off, color: Colors.grey),
      );
    }
    return Row(
      children: [
        DropdownButton<String>(
          value: _selectedPort,
          padding: EdgeInsets.zero,
          underline: Container(),
          items: _ports
              .map(
                (p) => DropdownMenuItem(
                  value: p,
                  child: Text(p, style: const TextStyle(fontSize: 12)),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedPort = v),
        ),
        IconButton(
          icon: Icon(
            _isScanning ? Icons.link : Icons.link_off,
            color: _isScanning ? Colors.green : Colors.grey,
          ),
          onPressed: _toggleConnection,
          tooltip: _isScanning ? 'Disconnect Reader' : 'Connect Reader',
        ),
      ],
    );
  }

  Widget _buildTripTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Trip Type:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('From College'),
                value: 'From College',
                groupValue: _tripType,
                onChanged: (v) => setState(() => _tripType = v!),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('To College'),
                value: 'To College',
                groupValue: _tripType,
                onChanged: (v) => setState(() => _tripType = v!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainMenu() {
    return Column(
      children: [
        _buildActionTile(
          icon: Icons.nfc,
          title: 'Scan by NFC',
          subtitle: 'Tap card to record trip',
          onTap: () {
            setState(() {
              _isNfcMode = true;
            });
          },
        ),
        const SizedBox(height: 10),
        _buildActionTile(
          icon: Icons.search,
          title: 'Search by ID',
          subtitle: 'Enter student ID manually',
          onTap: () => setState(() => _isSearchMode = true),
        ),
      ],
    );
  }

  Widget _buildNfcScanMode() {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _isNfcMode = false),
            ),
            const Text(
              "Scan Card",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 40),
        if (_isScanning)
          const Column(
            children: [
              Icon(Icons.nfc, size: 100, color: Colors.green),
              SizedBox(height: 20),
              Text(
                'Reader Ready',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 10),
              Text('Tap NFC card on the reader now'),
            ],
          )
        else
          Column(
            children: [
              const Icon(Icons.usb_off, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              const Text('Reader Not Connected'),
              TextButton(
                onPressed: _toggleConnection,
                child: const Text("Connect Now"),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSearchMode() {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _isSearchMode = false),
            ),
            Expanded(
              child: TextField(
                controller: _studentIdController,
                decoration: const InputDecoration(
                  labelText: 'Enter Student ID',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 10),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () {
                      if (_studentIdController.text.isNotEmpty) {
                        _processStudentId(_studentIdController.text.trim());
                      }
                    },
                    child: const Text('Go'),
                  ),
          ],
        ),
      ],
    );
  }

  Widget _buildReceipt() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Card(
          color: Colors.green.shade50,
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 50),
                const SizedBox(height: 10),
                const Text(
                  'Trip Recorded!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                _buildReceiptRow('Student ID', _receiptData!['id']),
                _buildReceiptRow('Name', _receiptData!['name']),
                _buildReceiptRow('Route', _receiptData!['route']),
                _buildReceiptRow('Stop', _receiptData!['stop']),
                _buildReceiptRow('Date', _receiptData!['time']),
                _buildReceiptRow('Trip Cost', '₹${_receiptData!['cost']}'),
                const Divider(),
                _buildReceiptRow(
                  'New Balance',
                  '₹${_receiptData!['balance']}',
                  isBold: true,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _receiptData = null;
                      _errorMessage = null;
                    });
                  },
                  child: const Text('Done / Next'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        onTap: onTap,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
