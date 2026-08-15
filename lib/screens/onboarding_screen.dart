import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  String _selectedAssembly = '1';
  String _selectedSection = 'C';

  final List<String> _assemblies = ['1', '2', '3', '4', '5'];
  final List<String> _sections = ['A', 'B', 'C'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _completeOnboarding() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<SettingsProvider>(context, listen: false);
      await provider.saveProfile(
        _nameController.text.trim(),
        _selectedAssembly,
        _selectedSection,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Setup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.account_circle,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to MYValve Log',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please set up your profile. This information will be used to auto-fill forms.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedAssembly,
                decoration: const InputDecoration(labelText: 'Assembly'),
                items: _assemblies.map((assembly) {
                  return DropdownMenuItem(
                    value: assembly,
                    child: Text('Assembly $assembly'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAssembly = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedSection,
                decoration: const InputDecoration(labelText: 'Section'),
                items: _sections.map((section) {
                  return DropdownMenuItem(
                    value: section,
                    child: Text('Section $section'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSection = value!;
                  });
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _completeOnboarding,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text('SAVE & CONTINUE', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
