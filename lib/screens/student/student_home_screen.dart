import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/bus_pass_request_model.dart';
import '../../services/auth_service.dart';
import 'apply_bus_pass_screen.dart';

class StudentHomeScreen extends StatelessWidget {
  final UserModel user;
  const StudentHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user.name}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text('Student ID: ${user.studentId ?? "N/A"}'),
            const SizedBox(height: 20),

            // Bus Pass Status Section
            if (user.busPassStatus == 'none')
              _buildApplyCard(context)
            else if (user.busPassStatus == 'pending')
              _buildPendingCard()
            else if (user.busPassStatus == 'approved')
              _buildActivePassCard(user.uid)
            else
              _buildRejectedCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildApplyCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('You do not have an active bus pass.'),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ApplyBusPassScreen(user: user),
                  ),
                );
              },
              child: const Text('Apply for Bus Pass'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingCard() {
    return const Card(
      color: Colors.orangeAccent,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.hourglass_empty),
            SizedBox(width: 10),
            Text('Your bus pass request is pending approval.'),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectedCard() {
    return const Card(
      color: Colors.redAccent,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.error),
            SizedBox(width: 10),
            Text('Your bus pass request was rejected.'),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePassCard(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bus_pass_requests')
          .where('studentId', isEqualTo: user.studentId)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('Error loading pass details');
        }

        final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final pass = BusPassRequestModel.fromMap(data);

        return Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Active Bus Pass',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Divider(),
                Text('Route: ${pass.routeName}'),
                Text('Stop: ${pass.stopName}'),
                Text(
                  'Balance: ₹${user.balance}',
                ), // Assuming balance is on user object
              ],
            ),
          ),
        );
      },
    );
  }
}
