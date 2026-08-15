import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _supportController = TextEditingController();

  @override
  void dispose() {
    _supportController.dispose();
    super.dispose();
  }

  final List<Color> _themeColors = const [
    Color(0xFF1E88E5), // Blue
    Color(0xFF43A047), // Green
    Color(0xFFE53935), // Red
    Color(0xFF8E24AA), // Purple
    Color(0xFFFFB300), // Amber
    Color(0xFF00ACC1), // Cyan
    Color(0xFF3949AB), // Indigo
    Color(0xFFF4511E), // Deep Orange
  ];

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // ── Profile Information with Edit Button ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profile Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Profile',
                onPressed: () =>
                    _showEditProfileDialog(context, settingsProvider),
              ),
            ],
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(
              settingsProvider.userName.isEmpty
                  ? 'No name set'
                  : settingsProvider.userName,
            ),
            subtitle: Text(
              'Assembly: ${settingsProvider.assembly.isEmpty ? '-' : settingsProvider.assembly}'
              '  |  Section: ${settingsProvider.section.isEmpty ? '-' : settingsProvider.section}',
            ),
          ),
          const Divider(height: 32),

          // ── Theme Mode ──
          const Text(
            'Theme Mode',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          RadioGroup<ThemeMode>(
            groupValue: settingsProvider.themeMode,
            onChanged: (ThemeMode? value) {
              if (value != null) settingsProvider.setThemeMode(value);
            },
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('Light'),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark'),
                  value: ThemeMode.dark,
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('System Default'),
                  value: ThemeMode.system,
                ),
              ],
            ),
          ),
          const Divider(height: 32),

          // ── App Colour ──
          const Text(
            'App Color',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _themeColors.map((color) {
              final isSelected =
                  settingsProvider.primaryColor.toARGB32() == color.toARGB32();
              return GestureDetector(
                onTap: () => settingsProvider.setPrimaryColor(color),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          const Divider(height: 32),

          // ── Help & Support ──
          const Text(
            'Help & Support',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _supportController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Describe your issue or query...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.send),
            label: const Text('Send Message'),
            onPressed: () => _sendSupportEmail(settingsProvider),
          ),
          const Divider(height: 32),
          
          // ── Built by RNEXT ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: InkWell(
                onTap: () => _showRnextDialog(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: RichText(
                    text: TextSpan(
                      text: 'Crafted by ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                      children: [
                        TextSpan(
                          text: 'RNEXT',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.cyanAccent
                                : Colors.cyan[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Edit Profile Dialog
  // ─────────────────────────────────────────────
  void _showEditProfileDialog(BuildContext context, SettingsProvider provider) {
    final nameController = TextEditingController(text: provider.userName);

    final List<String> assemblies = ['1', '2', '3', '4', '5'];
    final List<String> sections = ['A', 'B', 'C'];

    String selectedAssembly = assemblies.contains(provider.assembly)
        ? provider.assembly
        : assemblies.first;
    String selectedSection = sections.contains(provider.section)
        ? provider.section
        : sections.last;

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Edit Profile'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full Name
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Name / Signature',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Assembly Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedAssembly,
                      decoration: const InputDecoration(
                        labelText: 'Assembly',
                        prefixIcon: Icon(Icons.factory_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: assemblies.map((a) {
                        return DropdownMenuItem(
                          value: a,
                          child: Text('Assembly $a'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedAssembly = value);
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Section Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedSection,
                      decoration: const InputDecoration(
                        labelText: 'Section',
                        prefixIcon: Icon(Icons.grid_view_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: sections.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text('Section $s'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedSection = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter your name.'),
                        ),
                      );
                      return;
                    }
                    // Saves to SharedPreferences and calls notifyListeners()
                    // which automatically rebuilds the Settings screen.
                    provider.saveProfile(
                      name,
                      selectedAssembly,
                      selectedSection,
                    );
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  //  Send Support Email
  // ─────────────────────────────────────────────
  Future<void> _sendSupportEmail(SettingsProvider provider) async {
    final query = _supportController.text.trim();
    if (query.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a message first.')),
        );
      }
      return;
    }

    final name = provider.userName.isEmpty ? 'Not set' : provider.userName;
    final assembly = provider.assembly.isEmpty ? 'Not set' : provider.assembly;
    final section = provider.section.isEmpty ? 'Not set' : provider.section;

    final body = '''User Query: $query

--- User Details ---
Name: $name
Assembly: $assembly
Section: $section''';

    String? encodeQueryParameters(Map<String, String> params) {
      return params.entries
          .map((MapEntry<String, String> e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
    }

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'hello.rnext@gmail.com',
      query: encodeQueryParameters(<String, String>{
        'subject': 'MYValve Log - Support Query',
        'body': body,
      }),
    );

    try {
      final launched = await launchUrl(emailLaunchUri);
      if (!launched) {
        throw Exception('Could not launch email');
      } else {
        _supportController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email app')),
        );
      }
    }
  }

  // ─────────────────────────────────────────────
  //  RNEXT Dialog
  // ─────────────────────────────────────────────
  void _showRnextDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Column(
            children: [
              Text(
                'RNEXT',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                'BOUTIQUE DIGITAL LAB',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: const Text(
            'This app was proudly crafted by RNEXT.\n\nWe create premium websites, web applications, AI solutions, and modern digital experiences.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    try {
                      final uri = Uri.parse('https://rnextin.netlify.app/');
                      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                      if (!launched && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open the website')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open the website')),
                        );
                      }
                    }
                  },
                  child: const Text('Explore RNEXT', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white54,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
