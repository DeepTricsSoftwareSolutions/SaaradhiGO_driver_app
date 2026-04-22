import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saaradhi_go_driver/core/network/api_client.dart';
import 'package:saaradhi_go_driver/core/theme/theme.dart';
import 'package:saaradhi_go_driver/core/widgets/driver_button.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const EditProfileScreen({super.key, this.initialData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _aadharController;
  late TextEditingController _panController;
  late TextEditingController _vehicleNumberController;
  late TextEditingController _rcNumberController;
  late TextEditingController _vehicleBrandController;
  late TextEditingController _vehicleModelController;
  late TextEditingController _vehicleYearController;

  XFile? _vehiclePhotoFront;
  XFile? _vehiclePhotoBack;
  XFile? _vehiclePhotoInterior;
  XFile? _profilePhoto;

  bool _isLoading = false;
  String _errorMessage = '';

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fullNameController =
        TextEditingController(text: widget.initialData?['fullName'] ?? '');
    _aadharController =
        TextEditingController(text: widget.initialData?['aadharNumber'] ?? '');
    _panController =
        TextEditingController(text: widget.initialData?['panNumber'] ?? '');
    _vehicleNumberController =
        TextEditingController(text: widget.initialData?['vehicleNumber'] ?? '');
    _rcNumberController =
        TextEditingController(text: widget.initialData?['rcNumber'] ?? '');
    _vehicleBrandController =
        TextEditingController(text: widget.initialData?['vehicleBrand'] ?? '');
    _vehicleModelController =
        TextEditingController(text: widget.initialData?['vehicleModel'] ?? '');
    _vehicleYearController = TextEditingController(
        text: widget.initialData?['vehicleYear']?.toString() ?? '');
    _fetchCurrentProfile();
  }

  Future<void> _fetchCurrentProfile() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient().getProfile();
      final profileData = response.data;
      setState(() {
        _fullNameController.text = profileData['fullName'] ??
            profileData['name'] ??
            _fullNameController.text;
        _aadharController.text =
            profileData['aadharNumber'] ?? _aadharController.text;
        _panController.text = profileData['panNumber'] ?? _panController.text;
        _vehicleNumberController.text =
            profileData['vehicleNumber'] ?? _vehicleNumberController.text;
        _rcNumberController.text =
            profileData['rcNumber'] ?? _rcNumberController.text;
        _vehicleBrandController.text =
            profileData['vehicleBrand'] ?? _vehicleBrandController.text;
        _vehicleModelController.text =
            profileData['vehicleModel'] ?? _vehicleModelController.text;
        _vehicleYearController.text = profileData['vehicleYear']?.toString() ??
            _vehicleYearController.text;
      });
    } catch (e) {
      debugPrint('Failed to load profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _aadharController.dispose();
    _panController.dispose();
    _vehicleNumberController.dispose();
    _rcNumberController.dispose();
    _vehicleBrandController.dispose();
    _vehicleModelController.dispose();
    _vehicleYearController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          switch (type) {
            case 'front':
              _vehiclePhotoFront = image;
              break;
            case 'back':
              _vehiclePhotoBack = image;
              break;
            case 'interior':
              _vehiclePhotoInterior = image;
              break;
            case 'profile':
              _profilePhoto = image;
              break;
          }
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  bool _validateForm() {
    setState(() => _errorMessage = '');

    if (_fullNameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Full name is required');
      return false;
    }
    if (_aadharController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Aadhar number is required');
      return false;
    }
    if (_panController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'PAN number is required');
      return false;
    }
    if (_vehicleNumberController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Vehicle number is required');
      return false;
    }
    if (_rcNumberController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'RC number is required');
      return false;
    }
    if (_vehicleBrandController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Vehicle brand is required');
      return false;
    }
    if (_vehicleModelController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Vehicle model is required');
      return false;
    }
    if (_vehicleYearController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Vehicle year is required');
      return false;
    }

    return true;
  }

  Future<void> _submitProfile() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      await ApiClient().updateProfile({
        'fullName': _fullNameController.text.trim(),
        'aadharNumber': _aadharController.text.trim(),
        'panNumber': _panController.text.trim(),
        'vehicleNumber': _vehicleNumberController.text.trim(),
        'rcNumber': _rcNumberController.text.trim(),
        'vehicleBrand': _vehicleBrandController.text.trim(),
        'vehicleModel': _vehicleModelController.text.trim(),
        'vehicleYear': int.tryParse(_vehicleYearController.text.trim()),
      });

      if (_vehiclePhotoFront != null ||
          _vehiclePhotoBack != null ||
          _vehiclePhotoInterior != null ||
          _profilePhoto != null) {
        final formData = FormData();
        if (_profilePhoto != null) {
          formData.files.add(MapEntry(
            'profilePhoto',
            await MultipartFile.fromFile(_profilePhoto!.path,
                filename: _profilePhoto!.name),
          ));
        }
        if (_vehiclePhotoFront != null) {
          formData.files.add(MapEntry(
            'vehiclePhotoFront',
            await MultipartFile.fromFile(_vehiclePhotoFront!.path,
                filename: _vehiclePhotoFront!.name),
          ));
        }
        if (_vehiclePhotoBack != null) {
          formData.files.add(MapEntry(
            'vehiclePhotoBack',
            await MultipartFile.fromFile(_vehiclePhotoBack!.path,
                filename: _vehiclePhotoBack!.name),
          ));
        }
        if (_vehiclePhotoInterior != null) {
          formData.files.add(MapEntry(
            'vehiclePhotoInterior',
            await MultipartFile.fromFile(_vehiclePhotoInterior!.path,
                filename: _vehiclePhotoInterior!.name),
          ));
        }
        formData.fields.add(const MapEntry('submit', 'false'));
        await ApiClient().uploadDocuments(formData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppTheme.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      setState(() => _errorMessage = 'Failed to save profile');
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
          "EDIT PROFILE",
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personal Details Section
            FadeInUp(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "PERSONAL DETAILS",
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField("Full Name", _fullNameController, "John Doe"),
                  const SizedBox(height: 12),
                  _buildTextField(
                      "Aadhar Number", _aadharController, "1234 5678 9012",
                      isNumeric: true),
                  const SizedBox(height: 12),
                  _buildTextField("PAN Number", _panController, "ABCDE1234F",
                      isUppercase: true),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Vehicle Details Section
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "VEHICLE DETAILS",
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField("Vehicle Number", _vehicleNumberController,
                      "KA 01 AB 1234",
                      isUppercase: true),
                  const SizedBox(height: 12),
                  _buildTextField(
                      "RC Number", _rcNumberController, "DL 01 AB 0001234"),
                  const SizedBox(height: 12),
                  _buildTextField("Vehicle Brand", _vehicleBrandController,
                      "Maruti Suzuki"),
                  const SizedBox(height: 12),
                  _buildTextField(
                      "Vehicle Model", _vehicleModelController, "Swift"),
                  const SizedBox(height: 12),
                  _buildTextField(
                      "Vehicle Year", _vehicleYearController, "2023",
                      isNumeric: true),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Profile Photo Section
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "PROFILE PHOTO",
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5),
                  ),
                  const SizedBox(height: 12),
                  _buildPhotoCard("Profile Photo", _profilePhoto, 'profile'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Vehicle Photos Section
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "VEHICLE PHOTOS",
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5),
                  ),
                  const SizedBox(height: 12),
                  _buildPhotoCard("Front View", _vehiclePhotoFront, 'front'),
                  const SizedBox(height: 12),
                  _buildPhotoCard("Back View", _vehiclePhotoBack, 'back'),
                  const SizedBox(height: 12),
                  _buildPhotoCard(
                      "Interior View", _vehiclePhotoInterior, 'interior'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Error Message
            if (_errorMessage.isNotEmpty)
              FadeInUp(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.errorRed.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                        color: AppTheme.errorRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Save Button
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: DriverButton(
                onPressed: _isLoading ? null : _submitProfile,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("SAVE PROFILE"),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    bool isNumeric = false,
    bool isUppercase = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          textCapitalization: isUppercase
              ? TextCapitalization.characters
              : TextCapitalization.none,
          style: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppTheme.primaryGold, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: isUppercase
              ? (value) {
                  final cursorPos = controller.selection.base.offset;
                  controller.text = value.toUpperCase();
                  controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: cursorPos));
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildPhotoCard(String label, XFile? photo, String type) {
    final hasPhoto = photo != null;
    return GestureDetector(
      onTap: () => _pickImage(type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasPhoto
              ? AppTheme.successGreen.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasPhoto
                ? AppTheme.successGreen.withValues(alpha: 0.3)
                : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            if (hasPhoto && !kIsWeb)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(File(photo.path)),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    color: AppTheme.primaryGold, size: 28),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasPhoto ? "Photo attached" : "Tap to upload photo",
                    style: TextStyle(
                      color: hasPhoto ? AppTheme.successGreen : Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              hasPhoto ? Icons.check_circle : Icons.add_circle_outline,
              color: hasPhoto ? AppTheme.successGreen : AppTheme.primaryGold,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
