import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/bus_pass_request_model.dart';

class PassApprovalScreen extends StatelessWidget {
  const PassApprovalScreen({super.key});

  Future<void> _updateStatus(
    BuildContext context,
    BusPassRequestModel request,
    String newStatus,
  ) async {
    try {
      // 1. Update Request Status
      await FirebaseFirestore.instance
          .collection('bus_pass_requests')
          .doc(request.id)
          .update({'status': newStatus});

      // 2. Find User by Student ID and Update their status
      // Note: Ideally we should store uid in request to make this easier/safer
      // But based on current model, we query by studentId
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('studentId', isEqualTo: request.studentId)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        await userQuery.docs.first.reference.update({
          'bus_pass_status': newStatus,
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request $newStatus successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Bus Pass Requests')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bus_pass_requests')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pending requests'));
          }

          final requests = snapshot.data!.docs.map((doc) {
            return BusPassRequestModel.fromMap(
              doc.data() as Map<String, dynamic>,
            );
          }).toList();

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student: ${request.studentName}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('ID: ${request.studentId}'),
                      Text('Email: ${request.studentEmail}'),
                      const Divider(),
                      Text('Route: ${request.routeName}'),
                      Text('Stop: ${request.stopName}'),
                      Text('Cost: ₹${request.cost}'),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () =>
                                _updateStatus(context, request, 'rejected'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Reject'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () =>
                                _updateStatus(context, request, 'approved'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Approve'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
