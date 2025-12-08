import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../models/trip_model.dart';
import '../../models/bus_pass_request_model.dart';
import 'package:intl/intl.dart';

class AutomatedBusPassScreen extends StatefulWidget {
  const AutomatedBusPassScreen({super.key});

  @override
  State<AutomatedBusPassScreen> createState() => _AutomatedBusPassScreenState();
}

class _AutomatedBusPassScreenState extends State<AutomatedBusPassScreen> {
  String _tripType = 'From College';
  bool _isSearchMode = false;
  final _studentIdController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _receiptData;
  String? _errorMessage;

  Future<void> _processStudentId(String studentId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _receiptData = null;
    });

    try {
      // 1. Find User
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

      // 2. Get Pass Details
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

      // 3. Deduct & Record
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
      appBar: AppBar(title: const Text('Automated Bus Pass')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Trip Type Selector
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
            const Divider(),
            const SizedBox(height: 20),

            // Tiles
            if (!_isSearchMode && _receiptData == null) ...[
              _buildActionTile(
                icon: Icons.nfc,
                title: 'Scan by NFC',
                subtitle: 'Tap card to scan',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('NFC Scanning not implemented yet'),
                    ),
                  );
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

            // Search Mode
            if (_isSearchMode && _receiptData == null) ...[
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
                              _processStudentId(
                                _studentIdController.text.trim(),
                              );
                            }
                          },
                          child: const Text('Go'),
                        ),
                ],
              ),
            ],

            // Error Message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),

            // Receipt
            if (_receiptData != null) ...[
              const SizedBox(height: 20),
              Card(
                color: Colors.green.shade50,
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 50,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Trip Recorded!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      _buildReceiptRow('Student ID', _receiptData!['id']),
                      _buildReceiptRow('Name', _receiptData!['name']),
                      _buildReceiptRow('Route', _receiptData!['route']),
                      _buildReceiptRow('Stop', _receiptData!['stop']),
                      _buildReceiptRow('Date', _receiptData!['time']),
                      _buildReceiptRow(
                        'Trip Cost',
                        '₹${_receiptData!['cost']}',
                      ),
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
                            _isSearchMode = false;
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
          ],
        ),
      ),
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
