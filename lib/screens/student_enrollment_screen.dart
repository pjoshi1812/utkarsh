import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/form_validators.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

import 'dart:typed_data';

  
Uint8List? _photoBytes;
String? _photoUrlPreview;
bool _uploadingPhoto = false;

class StudentEnrollmentScreen extends StatefulWidget {
  const StudentEnrollmentScreen({super.key});

  @override
  State<StudentEnrollmentScreen> createState() => _StudentEnrollmentScreenState();
}

class _StudentEnrollmentScreenState extends State<StudentEnrollmentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Student Information
  final _studentNameController = TextEditingController();
  final _studentContactController = TextEditingController();
  final _studentWhatsAppController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _schoolController = TextEditingController();
  
  // Parent Information
  final _parentNameController = TextEditingController();
  final _parentContactController = TextEditingController();
  final _parentWhatsAppController = TextEditingController();
  final _occupationController = TextEditingController();
  final _parentEmailController = TextEditingController();
  
  // Academic Information
  final _previousMathsMarksController = TextEditingController();
  
  // Selection Variables
  String _studentType = 'New admission';
  String _studentWhatsAppOption = 'Same as above';
  String _parentWhatsAppOption = 'Same as above';
  String _selectedCourse = '8th';
  bool _isLoading = false;

  final List<String> _studentTypes = ['Existing', 'New admission'];
  final List<String> _whatsAppOptions = ['Same as above', 'Give whatsapp no'];
  final List<String> _courses = ['8th', '9th', '10th', '11th', '12th'];

  @override
  void dispose() {
    _studentNameController.dispose();
    _studentContactController.dispose();
    _studentWhatsAppController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _schoolController.dispose();
    _parentNameController.dispose();
    _parentContactController.dispose();
    _parentWhatsAppController.dispose();
    _occupationController.dispose();
    _parentEmailController.dispose();
    _previousMathsMarksController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() {
      _photoBytes = file.bytes!;
    });
  }

  Future<String?> _uploadPhotoIfAny(String uid) async {
    if (_photoBytes == null) return null;
    try {
      setState(() => _uploadingPhoto = true);
      final ref = FirebaseStorage.instance.ref().child('profile_photos').child('$uid.jpg');
      await ref.putData(_photoBytes!, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      setState(() {
        _uploadingPhoto = false;
        _photoUrlPreview = url;
      });
      return url;
    } catch (_) {
      setState(() => _uploadingPhoto = false);
      return null;
    }
  }

  void _updateWhatsAppFields() {
    setState(() {
      if (_studentWhatsAppOption == 'Same as above') {
        _studentWhatsAppController.text = _studentContactController.text;
      }
      if (_parentWhatsAppOption == 'Same as above') {
        _parentWhatsAppController.text = _parentContactController.text;
      }
    });
  }

  Future<void> _submitEnrollment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login first')),
        );
        return;
      }

      // Upload photo if any
      final uploadedUrl = await _uploadPhotoIfAny(user.uid);

      // Create enrollment data
      final enrollmentData = {
        'studentType': _studentType,
        'studentName': _studentNameController.text.trim(),
        'studentContact': _studentContactController.text.trim(),
        'studentWhatsApp': _studentWhatsAppController.text.trim(),
        'address': _addressController.text.trim(),
        'email': _emailController.text.trim(),
        'schoolCollege': _schoolController.text.trim(),
        'parentName': _parentNameController.text.trim(),
        'parentContact': _parentContactController.text.trim(),
        'parentWhatsApp': _parentWhatsAppController.text.trim(),
        'occupation': _occupationController.text.trim(),
        'parentEmail': _parentEmailController.text.trim(),
        'course': _selectedCourse,
        'previousMathsMarks': _previousMathsMarksController.text.trim(),
        'parentUid': user.uid,
        'enrollmentDate': FieldValue.serverTimestamp(),
        'status': 'pending',
        // Save profile photo URL
        'profilePhotoUrl': uploadedUrl ?? '',
      };

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('enrollments')
          .add(enrollmentData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enrollment submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      _formKey.currentState!.reset();
      _studentNameController.clear();
      _studentContactController.clear();
      _studentWhatsAppController.clear();
      _addressController.clear();
      _emailController.clear();
      _schoolController.clear();
      _parentNameController.clear();
      _parentContactController.clear();
      _parentWhatsAppController.clear();
      _occupationController.clear();
      _parentEmailController.clear();
      _previousMathsMarksController.clear();
      
      setState(() {
        _studentType = 'New admission';
        _studentWhatsAppOption = 'Same as above';
        _parentWhatsAppOption = 'Same as above';
        _selectedCourse = '8th';
        // Reset local photo state
        _photoBytes = null;
        _photoUrlPreview = null;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting enrollment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        title: const Text(
          'Student Enrollment',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.30,
              child: Image.asset('assets/bg_math.png', fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/utkarsh_logo.jpg',
                            height: 80,
                            width: 80,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Student Enrollment Form',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Please fill in all the required information',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Student Type Selection
                    _buildSectionCard(
                      'Student Type',
                      [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _studentType,
                            decoration: const InputDecoration(
                              labelText: 'Type of student *',
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.category, color: Colors.green),
                            ),
                            items: _studentTypes
                                .map((type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _studentType = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Student Information Section
                    _buildSectionCard(
                      'Student Information',
                      [
                        TextFormField(
                          controller: _studentNameController,
                          validator: (value) => FormValidators.validateName(value, 'Student Name'),
                          decoration: InputDecoration(
                            labelText: 'Name of student *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.person, color: Colors.green),
                          ),
                        ),
                        // Profile Photo section
                        Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundColor: Colors.green[100],
                                backgroundImage: _photoBytes != null
                                    ? MemoryImage(_photoBytes!)
                                    : (_photoUrlPreview != null && _photoUrlPreview!.isNotEmpty)
                                        ? NetworkImage(_photoUrlPreview!) as ImageProvider
                                        : null,
                                child: (_photoBytes == null &&
                                        (_photoUrlPreview == null || _photoUrlPreview!.isEmpty))
                                    ? const Icon(Icons.person, size: 48, color: Colors.green)
                                    : null,
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _uploadingPhoto ? null : _pickPhoto,
                                icon: _uploadingPhoto
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.photo),
                                label: Text(_uploadingPhoto ? 'Processing...' : 'Add Profile Photo'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _studentContactController,
                          keyboardType: TextInputType.phone,
                          validator: (value) => FormValidators.validatePhone(value),
                          decoration: InputDecoration(
                            labelText: 'Contact number *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.phone, color: Colors.green),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: _studentWhatsAppOption,
                                  decoration: const InputDecoration(
                                    labelText: 'WhatsApp No *',
                                    border: InputBorder.none,
                                    prefixIcon: Icon(Icons.message, color: Colors.green),
                                  ),
                                  items: _whatsAppOptions
                                      .map((option) => DropdownMenuItem(
                                            value: option,
                                            child: Text(option),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _studentWhatsAppOption = value!;
                                    });
                                    _updateWhatsAppFields();
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (_studentWhatsAppOption == 'Give whatsapp no')
                              Expanded(
                                child: TextFormField(
                                  controller: _studentWhatsAppController,
                                  keyboardType: TextInputType.phone,
                                  validator: (value) => FormValidators.validatePhone(value),
                                  decoration: InputDecoration(
                                    labelText: 'WhatsApp Number',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    prefixIcon: const Icon(Icons.message, color: Colors.green),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          maxLines: 3,
                          validator: (value) => FormValidators.validateRequired(value, 'Address'),
                          decoration: InputDecoration(
                            labelText: 'Address *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.location_on, color: Colors.green),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => FormValidators.validateEmail(value),
                          decoration: InputDecoration(
                            labelText: 'Email ID *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.email, color: Colors.green),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _schoolController,
                          validator: (value) => FormValidators.validateRequired(value, 'School/College'),
                          decoration: InputDecoration(
                            labelText: 'School/College name *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.school, color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Parent Information Section
                    _buildSectionCard(
                      'Parent/Guardian Information',
                      [
                        TextFormField(
                          controller: _parentNameController,
                          validator: (value) => FormValidators.validateName(value, 'Parent Name'),
                          decoration: InputDecoration(
                            labelText: 'Parents name *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.family_restroom, color: Colors.green),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _parentContactController,
                          keyboardType: TextInputType.phone,
                          validator: (value) => FormValidators.validatePhone(value),
                          decoration: InputDecoration(
                            labelText: 'Contact no *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.phone, color: Colors.green),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: _parentWhatsAppOption,
                                  decoration: const InputDecoration(
                                    labelText: 'WhatsApp No *',
                                    border: InputBorder.none,
                                    prefixIcon: Icon(Icons.message, color: Colors.green),
                                  ),
                                  items: _whatsAppOptions
                                      .map((option) => DropdownMenuItem(
                                            value: option,
                                            child: Text(option),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _parentWhatsAppOption = value!;
                                    });
                                    _updateWhatsAppFields();
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (_parentWhatsAppOption == 'Give whatsapp no')
                              Expanded(
                                child: TextFormField(
                                  controller: _parentWhatsAppController,
                                  keyboardType: TextInputType.phone,
                                  validator: (value) => FormValidators.validatePhone(value),
                                  decoration: InputDecoration(
                                    labelText: 'WhatsApp Number',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    prefixIcon: const Icon(Icons.message, color: Colors.green),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _occupationController,
                          validator: (value) => FormValidators.validateRequired(value, 'Occupation'),
                          decoration: InputDecoration(
                            labelText: 'Occupation *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.work, color: Colors.green),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _parentEmailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => FormValidators.validateEmail(value),
                          decoration: InputDecoration(
                            labelText: 'Email ID *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.email, color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Course Selection Section
                    _buildSectionCard(
                      'Course Information',
                      [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedCourse,
                            decoration: const InputDecoration(
                              labelText: 'Joining the academy for course *',
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.book, color: Colors.green),
                            ),
                            items: _courses
                                .map((course) => DropdownMenuItem(
                                      value: course,
                                      child: Text(course),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCourse = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _previousMathsMarksController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Previous year final marks of Maths is required';
                            }
                            final marks = int.tryParse(value.trim());
                            if (marks == null || marks < 0 || marks > 100) {
                              return 'Please enter valid marks between 0 and 100';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Previous year final marks of Maths *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.grade, color: Colors.green),
                            helperText: 'Enter marks out of 100',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitEnrollment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 5,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Submit Enrollment',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}