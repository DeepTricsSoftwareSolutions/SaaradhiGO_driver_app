import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:saaradhi_go_driver/features/auth/presentation/providers/auth_provider.dart';
import 'package:saaradhi_go_driver/core/theme/theme.dart';
import 'package:saaradhi_go_driver/core/network/api_client.dart';
import 'package:saaradhi_go_driver/core/widgets/driver_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _vehicleBrandController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _vehicleCapacityController = TextEditingController();

  // Selections
  String _gender = 'Male';
  String _vehicleType = 'Sedan';
  bool _isLoading = false;
  String _error = '';

  // Document tracking
  final Map<String, XFile?> _documents = {
    'Profile Photo': null,
    'Aadhaar Card': null,
    'Driving License': null,
    'Vehicle RC': null,
    'Vehicle Insurance': null,
  };

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _vehicleTypes = ['Sedan', 'SUV', 'Hatchback', 'Auto', 'Bike'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _vehicleBrandController.dispose();
    _vehicleNumberController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0) {
      // Validate personal details
      if (_nameController.text.trim().isEmpty) {
        setState(() => _error = 'Please enter your full name');
        return;
      }
      if (_phoneController.text.trim().length != 10) {
        setState(() => _error = 'Enter a valid 10-digit phone number');
        return;
      }
      if (_ageController.text.trim().isEmpty || int.tryParse(_ageController.text) == null) {
        setState(() => _error = 'Enter a valid age');
        return;
      }
    } else if (_currentPage == 1) {
      // Validate vehicle details
      if (_vehicleBrandController.text.trim().isEmpty) {
        setState(() => _error = 'Please enter vehicle brand');
        return;
      }
      if (_vehicleNumberController.text.trim().isEmpty) {
        setState(() => _error = 'Please enter vehicle number');
        return;
      }
      if (_vehicleCapacityController.text.trim().isEmpty || int.tryParse(_vehicleCapacityController.text) == null) {
        setState(() => _error = 'Please enter valid vehicle capacity');
        return;
      }
    }
    setState(() => _error = '');
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage++);
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage--;
        _error = '';
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_documents.values.any((v) => v != null)) {
      setState(() => _error = 'Please upload at least one document');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final int age = int.tryParse(_ageController.text.trim()) ?? 25;
      final String dob = "${DateTime.now().year - age}-01-01"; // Format for backend: YYYY-MM-DD

      // Extract raw phone and ensure +91 is added safely
      String rawPhone = _phoneController.text.trim();
      if (!rawPhone.startsWith('+91')) {
        rawPhone = '+91$rawPhone';
      }

      // Collect data and paths for later processing in OtpScreen (post-auth)
      final regData = {
        'full_name': _nameController.text.trim(),
        'phone_number': rawPhone,
        'dob': dob,
        'gender': _gender.toLowerCase(), // 'male', 'female', 'other' for /auth/update/
        'vehicle_type': _vehicleType.toUpperCase(), // Keeping uppercase for driver profile
        'vehicle_brand': _vehicleBrandController.text.trim(),
        'vehicle_number': _vehicleNumberController.text.trim(),
        'vehicle_capacity': _vehicleCapacityController.text.trim(),
        'document_paths': _documents.map((key, value) => MapEntry(key, value?.path)),
      };

      // Store in Provider for post-auth upload
      Provider.of<AuthProvider>(context, listen: false).setRegistrationData(regData);

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushNamed(
          context,
          '/otp',
          arguments: {
            'phone': _phoneController.text.trim(),
            'isRegistration': true,
          },
        );
      }
    } catch (e, stack) {
      debugPrint('[Registration] ❌ Error: $e');
      debugPrint('[Registration] ❌ Stack: $stack');
      if (mounted) {
        String errorMsg = 'Failed to submit: $e';
        if (e is DioException) {
          errorMsg = ApiClient.extractError(e);
        }
        setState(() {
          _error = errorMsg;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _prevPage,
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      padding: const EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Driver Registration',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Step ${_currentPage + 1} of 3',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Progress dots
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: List.generate(3, (i) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= _currentPage ? AppTheme.primaryGold : Colors.white12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 16),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPersonalDetailsPage(),
                  _buildVehicleDetailsPage(),
                  _buildDocumentsPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Page 1: Personal Details ──────────────────────────────────────────────
  Widget _buildPersonalDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInUp(
            child: const Text(
              'Personal Details',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
          const SizedBox(height: 4),
          const Text('Tell us about yourself', style: TextStyle(color: Colors.white38, fontSize: 14)),
          const SizedBox(height: 28),

          _buildLabel('Full Name'),
          _buildTextField(_nameController, 'e.g. Rajesh Kumar', Icons.person_outline),
          const SizedBox(height: 16),

          _buildLabel('Mobile Number'),
          _buildPhoneField(),
          const SizedBox(height: 16),

          _buildLabel('Age'),
          _buildTextField(_ageController, 'e.g. 28', Icons.cake_outlined,
              inputType: TextInputType.number),
          const SizedBox(height: 16),

          _buildLabel('Gender'),
          const SizedBox(height: 8),
          Row(
            children: _genders.map((g) {
              final selected = _gender == g;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _gender = g),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primaryGold.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? AppTheme.primaryGold : Colors.white12,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(g,
                          style: TextStyle(
                            color: selected ? AppTheme.primaryGold : Colors.white54,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          )),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          if (_error.isNotEmpty) _buildError(),
          const SizedBox(height: 28),
          DriverButton(onPressed: _nextPage, child: const Text('Next: Vehicle Details →')),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Page 2: Vehicle Details ───────────────────────────────────────────────
  Widget _buildVehicleDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInUp(
            child: const Text(
              'Vehicle Details',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
          const SizedBox(height: 4),
          const Text('Your vehicle information', style: TextStyle(color: Colors.white38, fontSize: 14)),
          const SizedBox(height: 28),

          _buildLabel('Vehicle Type'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _vehicleTypes.map((type) {
              final selected = _vehicleType == type;
              return GestureDetector(
                onTap: () => setState(() => _vehicleType = type),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primaryGold.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? AppTheme.primaryGold : Colors.white12,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(type,
                      style: TextStyle(
                        color: selected ? AppTheme.primaryGold : Colors.white54,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          _buildLabel('Vehicle Brand / Model'),
          _buildTextField(_vehicleBrandController, 'e.g. Maruti Swift', Icons.directions_car_outlined),
          const SizedBox(height: 16),

          _buildLabel('Vehicle Registration Number'),
          _buildTextField(_vehicleNumberController, 'e.g. TS09AB1234', Icons.pin_outlined),
          const SizedBox(height: 16),

          _buildLabel('Passenger Capacity'),
          _buildTextField(_vehicleCapacityController, 'e.g. 4', Icons.group_outlined, inputType: TextInputType.number),

          if (_error.isNotEmpty) _buildError(),
          const SizedBox(height: 28),
          DriverButton(onPressed: _nextPage, child: const Text('Next: Documents →')),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Page 3: Documents ─────────────────────────────────────────────────────
  Widget _buildDocumentsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInUp(
            child: const Text(
              'Upload Documents',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
          const SizedBox(height: 4),
          const Text('Required for verification & approval', style: TextStyle(color: Colors.white38, fontSize: 14)),
          const SizedBox(height: 28),

          ..._documents.entries.map((entry) {
            return _buildDocumentTile(entry.key, entry.value);
          }),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.1)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryGold, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your documents will be reviewed and approved by our team within 24 hours.',
                    style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          if (_error.isNotEmpty) _buildError(),
          const SizedBox(height: 28),
          DriverButton(
            onPressed: _handleSubmit,
            isLoading: _isLoading,
            backgroundColor: AppTheme.successGreen,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 20),
                SizedBox(width: 8),
                Text('Submit & Verify OTP'),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _buildDocumentTile(String name, XFile? file) {
    final bool uploaded = file != null;
    return GestureDetector(
      onTap: () async {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          setState(() => _documents[name] = image);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: uploaded ? AppTheme.successGreen.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: uploaded ? AppTheme.successGreen.withValues(alpha: 0.2) : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: uploaded
                    ? AppTheme.successGreen.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                uploaded ? Icons.check_circle : Icons.upload_file_outlined,
                color: uploaded ? AppTheme.successGreen : Colors.white38,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                        color: uploaded ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      )),
                  Text(uploaded ? 'Uploaded ✓' : 'Tap to upload',
                      style: TextStyle(
                        color: uploaded ? AppTheme.successGreen : Colors.white24,
                        fontSize: 12,
                      )),
                ],
              ),
            ),
            Icon(
              uploaded ? Icons.edit_outlined : Icons.add_circle_outline,
              color: uploaded ? AppTheme.successGreen : Colors.white24,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      );

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType inputType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.white38, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Text('🇮🇳', style: TextStyle(fontSize: 16)),
                SizedBox(width: 6),
                Text('+91', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w700)),
                SizedBox(width: 6),
                Text('|', style: TextStyle(color: Colors.white12)),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 2),
              decoration: const InputDecoration(
                counterText: '',
                hintText: '10-digit number',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.errorRed.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_error,
                    style: const TextStyle(color: AppTheme.errorRed, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
}
