import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/route_model.dart';
import '../../services/route_service.dart';

class AddRouteScreen extends StatefulWidget {
  const AddRouteScreen({super.key});

  @override
  State<AddRouteScreen> createState() => _AddRouteScreenState();
}

class _AddRouteScreenState extends State<AddRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _routeNameController = TextEditingController();
  final List<TextEditingController> _stopControllers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Start with 1 stop
    _addStop();
  }

  void _addStop() {
    if (_stopControllers.length < 15) {
      setState(() {
        _stopControllers.add(TextEditingController());
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Maximum 15 stops allowed')));
    }
  }

  void _removeStop(int index) {
    setState(() {
      _stopControllers[index].dispose();
      _stopControllers.removeAt(index);
    });
  }

  @override
  void dispose() {
    _routeNameController.dispose();
    for (var controller in _stopControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Routes')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _routeNameController,
                decoration: const InputDecoration(labelText: 'Route Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Enter route name' : null,
              ),
              const SizedBox(height: 20),
              const Text(
                'Stops (Max 15)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _stopControllers.length,
                  itemBuilder: (context, index) {
                    int stopNumber = index + 1;
                    double cost = stopNumber * 10.0;
                    return ListTile(
                      title: TextFormField(
                        controller: _stopControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Stop $stopNumber Name',
                          suffixText: '₹$cost',
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Enter stop name' : null,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeStop(index),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _addStop,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Stop'),
                  ),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              if (_stopControllers.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Add at least one stop'),
                                  ),
                                );
                                return;
                              }

                              setState(() => _isLoading = true);

                              List<StopModel> stops = [];
                              for (
                                int i = 0;
                                i < _stopControllers.length;
                                i++
                              ) {
                                stops.add(
                                  StopModel(
                                    name: _stopControllers[i].text.trim(),
                                    stopNumber: i + 1,
                                    cost: (i + 1) * 10.0,
                                  ),
                                );
                              }

                              final route = RouteModel(
                                id: const Uuid().v4(),
                                name: _routeNameController.text.trim(),
                                stops: stops,
                              );

                              // We need to provide RouteService via Provider or instantiate it
                              // Assuming we'll add it to MultiProvider in main.dart
                              // For now, let's just instantiate it here or use Provider if available
                              final routeService = RouteService();

                              String? error = await routeService.addRoute(
                                route,
                              );

                              setState(() => _isLoading = false);

                              if (error != null) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(error)));
                              } else {
                                Navigator.pop(context);
                              }
                            }
                          },
                          child: const Text('Save Route'),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
