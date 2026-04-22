import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:saaradhi_go_driver/core/theme/theme.dart';
import 'package:saaradhi_go_driver/features/auth/presentation/providers/auth_provider.dart';
import 'package:saaradhi_go_driver/core/widgets/driver_button.dart';
import 'package:saaradhi_go_driver/core/widgets/glass_card.dart';
import 'package:saaradhi_go_driver/core/network/api_client.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  State<VehicleManagementScreen> createState() =>
      _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _numberController = TextEditingController();
  final _capacityController = TextEditingController();
  final _yearController = TextEditingController();

  String _vehicleType = 'Sedan';
  bool _isLoading = false;

  final List<String> _vehicleTypes = [
    'Sedan',
    'SUV',
    'Hatchback',
    'Auto',
    'Bike'
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentVehicleData();
  }

  void _loadCurrentVehicleData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null) {
      _brandController.text = user['vehicleBrand'] ?? '';
      _modelController.text = user['vehicleModel'] ?? '';
      _numberController.text = user['vehicleNumber'] ?? '';
      _capacityController.text = (user['vehicleCapacity'] ?? '').toString();
      _yearController.text = (user['vehicleYear'] ?? '').toString();
      _vehicleType = user['vehicleType'] ?? 'Sedan';
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _numberController.dispose();
    _capacityController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _updateVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiClient().updateProfile({
        'vehicleType': _vehicleType,
        'vehicleBrand': _brandController.text.trim(),
        'vehicleModel': _modelController.text.trim(),
        'vehicleNumber': _numberController.text.trim(),
        'vehicleCapacity': int.parse(_capacityController.text.trim()),
        'vehicleYear': _yearController.text.trim().isNotEmpty
            ? int.parse(_yearController.text.trim())
            : null,
      });

      if (response.data['status'] == 'OK') {
        if (!mounted) return;

        // Refresh user data
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.refreshProfile();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle details updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update vehicle details'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "VEHICLE MANAGEMENT",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Vehicle Info Card
              FadeInDown(
                child: GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "VEHICLE DETAILS",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Vehicle Type
                      const Text(
                        "Vehicle Type",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _vehicleType,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF2A2A2A),
                            style: const TextStyle(color: Colors.white),
                            items: _vehicleTypes.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _vehicleType = value!);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Brand
                      TextFormField(
                        controller: _brandController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Brand',
                          labelStyle: TextStyle(color: Colors.white70),
                          hintText: 'e.g., Toyota, Honda',
                          hintStyle: TextStyle(color: Colors.white38),
                        ),
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return 'Please enter vehicle brand';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Model
                      TextFormField(
                        controller: _modelController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Model',
                          labelStyle: TextStyle(color: Colors.white70),
                          hintText: 'e.g., Camry, Civic',
                          hintStyle: TextStyle(color: Colors.white38),
                        ),
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return 'Please enter vehicle model';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Number
                      TextFormField(
                        controller: _numberController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'License Plate Number',
                          labelStyle: TextStyle(color: Colors.white70),
                          hintText: 'e.g., KA01AB1234',
                          hintStyle: TextStyle(color: Colors.white38),
                        ),
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return 'Please enter vehicle number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Capacity
                      TextFormField(
                        controller: _capacityController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Passenger Capacity',
                          labelStyle: TextStyle(color: Colors.white70),
                          hintText: 'e.g., 4',
                          hintStyle: TextStyle(color: Colors.white38),
                        ),
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return 'Please enter capacity';
                          }
                          final capacity = int.tryParse(value!);
                          if (capacity == null || capacity < 1) {
                            return 'Please enter valid capacity';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Year
                      TextFormField(
                        controller: _yearController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Manufacturing Year (Optional)',
                          labelStyle: TextStyle(color: Colors.white70),
                          hintText: 'e.g., 2020',
                          hintStyle: TextStyle(color: Colors.white38),
                        ),
                        validator: (value) {
                          if (value?.trim().isNotEmpty ?? false) {
                            final year = int.tryParse(value!);
                            if (year == null ||
                                year < 2000 ||
                                year > DateTime.now().year + 1) {
                              return 'Please enter valid year';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Update Button
              FadeInUp(
                child: DriverButton(
                  onPressed: _isLoading ? null : _updateVehicle,
                  backgroundColor: AppTheme.primaryGold,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Text("UPDATE VEHICLE"),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
