import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/route_model.dart';
import '../../models/bus_pass_request_model.dart';
import '../../services/route_service.dart';

class ApplyBusPassScreen extends StatefulWidget {
  final UserModel user;
  const ApplyBusPassScreen({super.key, required this.user});

  @override
  State<ApplyBusPassScreen> createState() => _ApplyBusPassScreenState();
}

class _ApplyBusPassScreenState extends State<ApplyBusPassScreen> {
  final _formKey = GlobalKey<FormState>();
  RouteModel? _selectedRoute;
  StopModel? _selectedStop;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final routeService = RouteService(); // Ideally use Provider

    return Scaffold(
      appBar: AppBar(title: const Text('Apply Bus Pass')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Student ID: ${widget.user.studentId ?? "N/A"}'),
                Text('Name: ${widget.user.name}'),
                const SizedBox(height: 20),

                // Route Dropdown
                StreamBuilder<List<RouteModel>>(
                  stream: routeService.getRoutes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('No routes available');
                    }

                    return DropdownButtonFormField<RouteModel>(
                      decoration: const InputDecoration(
                        labelText: 'Select Route',
                      ),
                      value: _selectedRoute,
                      items: snapshot.data!.map((route) {
                        return DropdownMenuItem(
                          value: route,
                          child: Text(route.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRoute = value;
                          _selectedStop = null; // Reset stop
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Select a route' : null,
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Stop Dropdown (Dependent on Route)
                if (_selectedRoute != null)
                  DropdownButtonFormField<StopModel>(
                    decoration: const InputDecoration(labelText: 'Select Stop'),
                    value: _selectedStop,
                    items: _selectedRoute!.stops.map((stop) {
                      return DropdownMenuItem(
                        value: stop,
                        child: Text('${stop.name} (Stop ${stop.stopNumber})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStop = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Select a stop' : null,
                  ),

                const SizedBox(height: 20),

                // Cost Display
                if (_selectedStop != null)
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'Your single trip cost is ₹${_selectedStop!.cost}',
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Total Fee to be paid: ₹${_selectedStop!.cost * 40}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => _isLoading = true);

                              final request = BusPassRequestModel(
                                id: const Uuid().v4(),
                                studentId: widget.user.studentId ?? '',
                                studentName: widget.user.name,
                                studentEmail: widget.user.email, // Pass email
                                routeId: _selectedRoute!.id,
                                routeName: _selectedRoute!.name,
                                stopName: _selectedStop!.name,
                                cost: _selectedStop!
                                    .cost, // Storing single trip cost as personal fare
                                requestDate: DateTime.now(),
                                status: 'pending',
                              );

                              final double totalFee = _selectedStop!.cost * 40;

                              try {
                                // Save request
                                await FirebaseFirestore.instance
                                    .collection('bus_pass_requests')
                                    .doc(request.id)
                                    .set(request.toMap());

                                // Update user status and balance
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(widget.user.uid)
                                    .update({
                                      'bus_pass_status': 'pending',
                                      'balance': totalFee,
                                    });

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Application Submitted!'),
                                    ),
                                  );
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }

                              setState(() => _isLoading = false);
                            }
                          },
                          child: const Text('Apply for Bus Pass'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
