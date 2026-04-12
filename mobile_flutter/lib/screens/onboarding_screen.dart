import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/theme.dart';
import 'widgets/driver_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 1;
  bool _isLoading = false;

  // Step 1: Personal
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  XFile? _profilePhoto;

  // Step 2: Vehicle
  final TextEditingController _vehicleNumController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  String _vehicleType = "4W";

  // Step 3: Docs
  final Map<String, XFile?> _docs = {
    "Driving License": null,
    "Vehicle RC": null,
    "Vehicle Insurance": null,
  };

  final ImagePicker _picker = ImagePicker();

  void _nextStep() => setState(() => _step++);
  void _prevStep() => setState(() => _step--);

  Future<void> _pickImage(String label, {bool isProfile = false}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          if (isProfile) {
            _profilePhoto = image;
          } else {
            _docs[label] = image;
          }
        });
      }
    } catch (e) {
      debugPrint("Error picking image: \$e");
    }
  }

  bool _isStep1Valid() =>
      _nameController.text.isNotEmpty &&
      _emailController.text.isNotEmpty &&
      _profilePhoto != null;

  bool _isStep2Valid() =>
      _vehicleNumController.text.isNotEmpty &&
      _capacityController.text.isNotEmpty;

  bool _isStep3Valid() => _docs.values.every((v) => v != null);

  Future<void> _submitRegistration() async {
    if (!_isStep1Valid() || !_isStep2Valid() || !_isStep3Valid()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final formData = FormData.fromMap({
        'full_name': _nameController.text,
        'email': _emailController.text,
        'vehicle_type': _vehicleType, // e.g., '2W' or '4W'
        'vehicle_number': _vehicleNumController.text,
        'capacity': _capacityController.text,
      });

      // Helper for files
      Future<void> appendFile(String fieldName, XFile? file) async {
        if (file == null) return;
        if (kIsWeb) {
          final bytes = await file.readAsBytes();
          formData.files.add(MapEntry(
            fieldName,
            MultipartFile.fromBytes(bytes, filename: file.name),
          ));
        } else {
          formData.files.add(MapEntry(
            fieldName,
            await MultipartFile.fromFile(file.path, filename: file.name),
          ));
        }
      }

      await appendFile('profile_photo', _profilePhoto);
      await appendFile('driving_license', _docs['Driving License']);
      await appendFile('rc_document', _docs['Vehicle RC']);
      await appendFile('insurance_document', _docs['Vehicle Insurance']);
      
      await ApiClient().uploadDocuments(formData);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/verification');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed. Please try again.')),
        );
      }
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_step > 1)
                    IconButton(
                      onPressed: _prevStep,
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    )
                  else
                    const SizedBox(width: 44),
                  const Text(
                    "DRIVER REGISTRATION",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
              const SizedBox(height: 24),
              // Step Indicator
              Row(
                children: [1, 2, 3].map((s) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: s <= _step ? AppTheme.primaryGold : Colors.white10,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              // Content
              Expanded(child: _buildStepContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      default:
        return Container();
    }
  }

  // ─── STEP 1: PERSONAL ──────────────────────────────────────────────────────
  Widget _buildStep1() {
    return FadeInRight(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Personal Details",
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
            const SizedBox(height: 8),
            const Text("Upload a clear photo and your details",
                style: TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 40),
            Center(
              child: GestureDetector(
                onTap: () => _pickImage("profile", isProfile: true),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryGold, width: 2),
                    image: _profilePhoto != null
                        ? DecorationImage(
                            image: kIsWeb
                                ? NetworkImage(_profilePhoto!.path)
                                : FileImage(File(_profilePhoto!.path))
                                    as ImageProvider,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _profilePhoto == null
                      ? const Icon(Icons.add_a_photo,
                          color: AppTheme.primaryGold, size: 32)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text("Profile Photo",
                  style: TextStyle(
                      color: AppTheme.primaryGold,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
            _buildField(
              label: "FULL NAME",
              hint: "Enter your full name",
              icon: Icons.person_outline,
              controller: _nameController,
            ),
            const SizedBox(height: 24),
            _buildField(
              label: "EMAIL ADDRESS",
              hint: "Enter email address",
              icon: Icons.email_outlined,
              controller: _emailController,
            ),
            const SizedBox(height: 40),
            DriverButton(
              onPressed: _isStep1Valid() ? _nextStep : null,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("CONTINUE"),
                  SizedBox(width: 8),
                  Icon(Icons.chevron_right),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── STEP 2: VEHICLE ───────────────────────────────────────────────────────
  Widget _buildStep2() {
    return FadeInRight(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Vehicle Details",
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
            const SizedBox(height: 8),
            const Text("Details of the vehicle you'll drive",
                style: TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 40),
            Row(
              children: [
                _buildVehicleChoice("2W", Icons.motorcycle_outlined, "Bike / Moto"),
                const SizedBox(width: 16),
                _buildVehicleChoice("4W", Icons.directions_car_outlined, "Car / Cab"),
              ],
            ),
            const SizedBox(height: 40),
            _buildField(
              label: "VEHICLE REGISTRATION NUMBER",
              hint: "Ex: TS 07 EX 1234",
              controller: _vehicleNumController,
              textAlign: TextAlign.center,
              textStyle: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2),
              onChanged: (v) => setState(
                  () => _vehicleNumController.text = v.toUpperCase()),
            ),
            const SizedBox(height: 24),
            _buildField(
              label: "VEHICLE CAPACITY (PASSENGERS)",
              hint: "Ex: 4",
              icon: Icons.people_outline,
              controller: _capacityController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 40),
            DriverButton(
              onPressed: _isStep2Valid() ? _nextStep : null,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("VERIFY DOCUMENTS"),
                  SizedBox(width: 8),
                  Icon(Icons.chevron_right),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── STEP 3: DOCS ──────────────────────────────────────────────────────────
  Widget _buildStep3() {
    return FadeInRight(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Upload Documents",
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
            const SizedBox(height: 8),
            const Text("Upload clear photos of your documents",
                style: TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 32),
            ..._docs.entries.map((doc) => _buildDocCard(doc.key, doc.value)),
            const SizedBox(height: 40),
            DriverButton(
              onPressed: (_isStep3Valid() && !_isLoading)
                  ? _submitRegistration
                  : null,
              child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : const Text("SUBMIT REGISTRATION"),
            ),
          ],
        ),
      ),
    );
  }

  // ─── UTILS ─────────────────────────────────────────────────────────────────
  Widget _buildField({
    required String label,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
    required TextEditingController controller,
    TextAlign textAlign = TextAlign.start,
    TextStyle? textStyle,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          textAlign: textAlign,
          keyboardType: keyboardType,
          style: textStyle ??
              const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
          onChanged: (v) {
            if (onChanged != null) onChanged(v);
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            prefixIcon:
                icon != null ? Icon(icon, color: AppTheme.primaryGold) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleChoice(String type, IconData icon, String label) {
    bool isSelected = _vehicleType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _vehicleType = type),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryGold.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isSelected ? AppTheme.primaryGold : Colors.white10,
                width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: isSelected ? AppTheme.primaryGold : Colors.white54,
                  size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocCard(String label, XFile? file) {
    bool isUploaded = file != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _pickImage(label),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isUploaded
                ? AppTheme.successGreen.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isUploaded
                  ? AppTheme.successGreen.withValues(alpha: 0.4)
                  : Colors.white10,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                  image: isUploaded
                      ? DecorationImage(
                          image: kIsWeb
                              ? NetworkImage(file.path)
                              : FileImage(File(file.path)) as ImageProvider,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !isUploaded
                    ? Icon(
                        label.contains("License")
                            ? Icons.credit_card
                            : Icons.file_present_outlined,
                        color: AppTheme.primaryGold,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      isUploaded ? "Document Attached" : "Tap to upload scan",
                      style: TextStyle(
                          color: isUploaded
                              ? AppTheme.successGreen
                              : Colors.white54,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(
                isUploaded ? Icons.check_circle : Icons.camera_alt_outlined,
                color: isUploaded ? AppTheme.successGreen : Colors.white54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
