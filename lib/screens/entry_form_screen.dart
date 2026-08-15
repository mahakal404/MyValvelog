import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/heart_valve_entry.dart';
import '../providers/entry_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/banner_ad_widget.dart';

class EntryFormScreen extends StatefulWidget {
  final HeartValveEntry? entryToEdit;

  const EntryFormScreen({super.key, this.entryToEdit});

  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Field Controllers
  final _serialNoController = TextEditingController();
  final _batchNoController = TextEditingController();
  final _jobCardNoController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _signController = TextEditingController();

  final _modelController = TextEditingController();
  final _sizeController = TextEditingController();

  String _selectedModel = 'THV';
  final List<String> _models = ['THV', 'THV2', 'Model 4', 'THVP5', 'Model 6'];
  bool _manualModel = false;

  String _selectedSize = '20';
  final List<String> _sizes = [
    '20',
    '21.5',
    '23',
    '24.5',
    '26',
    '27.5',
    '29',
    '30.5',
    '32',
    '35',
  ];
  bool _manualSize = false;

  String _selectedAssembly = '1';
  final List<String> _assemblies = ['1', '2', '3', '4', '5'];

  String _selectedSection = 'C';
  final List<String> _sections = ['A', 'B', 'C'];

  bool _isBorrowed = false;
  String? _borrowedFromAssembly;

  DateTime? _takeTime;
  DateTime? _submitTime;

  bool _isInit = true;

  @override
  void initState() {
    super.initState();
    _serialNoController.addListener(_syncSerialToBatch);
  }

  void _syncSerialToBatch() {
    final text = _serialNoController.text;
    if (text.isEmpty) return;

    // Mirror up to 8 characters to represent model + batch code
    final batchLength = text.length > 8 ? 8 : text.length;
    final prefix = text.substring(0, batchLength);

    if (!_batchNoController.text.startsWith(prefix)) {
      _batchNoController.value = TextEditingValue(
        text: prefix,
        selection: TextSelection.collapsed(offset: prefix.length),
      );
    }
  }

  void _onModelChanged(String model) {
    // Model Prefix Pre-fill
    _serialNoController.value = TextEditingValue(
      text: model,
      selection: TextSelection.collapsed(offset: model.length),
    );

    // Job Card Auto-fill
    final now = DateTime.now();
    final mmm = DateFormat('MMM').format(now).toUpperCase();
    final yy = DateFormat('yy').format(now);
    final suffix = '/$mmm/$yy';

    if (model == 'THV2' || model == 'THVP5') {
      final jobCard = 'TVASM$suffix';
      _jobCardNoController.value = TextEditingValue(
        text: jobCard,
        selection: TextSelection.collapsed(offset: jobCard.length),
      );
    } else {
      _jobCardNoController.value = TextEditingValue(
        text: suffix,
        // Place cursor at the beginning so they can type the prefix
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      if (widget.entryToEdit != null) {
        final entry = widget.entryToEdit!;

        if (_models.contains(entry.model)) {
          _selectedModel = entry.model;
          _manualModel = false;
        } else {
          _manualModel = true;
          _modelController.text = entry.model;
        }

        if (_sizes.contains(entry.size)) {
          _selectedSize = entry.size;
          _manualSize = false;
        } else {
          _manualSize = true;
          _sizeController.text = entry.size;
        }

        _serialNoController.text = entry.serialNo;
        _batchNoController.text = entry.batchNo;
        _jobCardNoController.text = entry.jobCardNo;
        _quantityController.text = entry.quantity.toString();
        _signController.text = entry.sign;
        _selectedAssembly = _assemblies.contains(entry.assembly)
            ? entry.assembly
            : _assemblies.first;
        _selectedSection = _sections.contains(entry.section)
            ? entry.section
            : _sections.first;
        _isBorrowed =
            entry.borrowedFromAssembly != null &&
            entry.borrowedFromAssembly!.isNotEmpty;
        if (_isBorrowed) {
          _borrowedFromAssembly = entry.borrowedFromAssembly;
        }
        _takeTime = entry.takeTime;
        _submitTime = entry.submitTime;
      } else {
        // New entry, auto-fill from SettingsProvider
        final settings = Provider.of<SettingsProvider>(context, listen: false);
        _signController.text = settings.userName;
        if (_assemblies.contains(settings.assembly)) {
          _selectedAssembly = settings.assembly;
        }
        if (_sections.contains(settings.section)) {
          _selectedSection = settings.section;
        }
        _takeTime = DateTime.now();
        // Submit time is left null initially for a new entry until user submits it
      }
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _serialNoController.removeListener(_syncSerialToBatch);
    _serialNoController.dispose();
    _batchNoController.dispose();
    _jobCardNoController.dispose();
    _quantityController.dispose();
    _signController.dispose();
    _modelController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context, bool isTakeTime) async {
    final initialDate = isTakeTime
        ? (_takeTime ?? DateTime.now())
        : (_submitTime ?? DateTime.now());

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (selectedDate == null) return;

    if (!context.mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (selectedTime == null) return;

    setState(() {
      final newDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
      if (isTakeTime) {
        _takeTime = newDateTime;
      } else {
        _submitTime = newDateTime;
      }
    });
  }

  Future<void> _saveEntry() async {
    if (_formKey.currentState!.validate()) {
      if (_takeTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select Take Time')),
        );
        return;
      }

      final entry = HeartValveEntry(
        id: widget.entryToEdit?.id,
        model: _manualModel ? _modelController.text.trim() : _selectedModel,
        serialNo: _serialNoController.text.trim(),
        batchNo: _batchNoController.text.trim(),
        jobCardNo: _jobCardNoController.text.trim(),
        size: _manualSize ? _sizeController.text.trim() : _selectedSize,
        quantity: int.tryParse(_quantityController.text) ?? 1,
        sign: _signController.text.trim(),
        assembly: _selectedAssembly,
        section: _selectedSection,
        borrowedFromAssembly: _isBorrowed ? _borrowedFromAssembly : null,
        takeTime: _takeTime!,
        submitTime: _submitTime ?? DateTime.now(), // default to now if not set
        timestamp: widget.entryToEdit?.timestamp ?? DateTime.now(),
      );

      final provider = Provider.of<EntryProvider>(context, listen: false);

      if (widget.entryToEdit == null) {
        await provider.addEntry(entry);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entry saved successfully')),
          );
        }
      } else {
        await provider.updateEntry(entry);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Entry updated successfully')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context); // Go back
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.entryToEdit == null ? 'New Entry' : 'Edit Entry'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            CheckboxListTile(
                              title: const Text('Enter Model Manually'),
                              contentPadding: EdgeInsets.zero,
                              value: _manualModel,
                              onChanged: (value) {
                                setState(() {
                                  _manualModel = value ?? false;
                                });
                              },
                            ),
                            if (!_manualModel)
                              DropdownButtonFormField<String>(
                                initialValue: _selectedModel,
                                decoration: const InputDecoration(
                                  labelText: 'Model',
                                ),
                                items: _models.map((model) {
                                  return DropdownMenuItem(
                                    value: model,
                                    child: Text(model),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedModel = value!;
                                    _onModelChanged(_selectedModel);
                                  });
                                },
                              )
                            else
                              TextFormField(
                                controller: _modelController,
                                decoration: const InputDecoration(
                                  labelText: 'Model',
                                ),
                              ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _serialNoController,
                              textCapitalization: TextCapitalization.characters,
                              keyboardType: TextInputType.visiblePassword,
                              decoration: const InputDecoration(
                                labelText: 'Serial No.',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _batchNoController,
                              textCapitalization: TextCapitalization.characters,
                              keyboardType: TextInputType.visiblePassword,
                              decoration: const InputDecoration(
                                labelText: 'Batch No.',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _jobCardNoController,
                              textCapitalization: TextCapitalization.characters,
                              keyboardType: TextInputType.visiblePassword,
                              decoration: const InputDecoration(
                                labelText: 'Job Card No',
                              ),
                            ),
                            const SizedBox(height: 16),
                            CheckboxListTile(
                              title: const Text('Enter Size Manually'),
                              contentPadding: EdgeInsets.zero,
                              value: _manualSize,
                              onChanged: (value) {
                                setState(() {
                                  _manualSize = value ?? false;
                                });
                              },
                            ),
                            if (!_manualSize)
                              DropdownButtonFormField<String>(
                                initialValue: _selectedSize,
                                decoration: const InputDecoration(
                                  labelText: 'Size',
                                ),
                                items: _sizes.map((size) {
                                  return DropdownMenuItem(
                                    value: size,
                                    child: Text(size),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSize = value!;
                                  });
                                },
                              )
                            else
                              TextFormField(
                                controller: _sizeController,
                                decoration: const InputDecoration(
                                  labelText: 'Size',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _quantityController,
                              decoration: const InputDecoration(
                                labelText: 'Quantity',
                                filled: true,
                              ),
                              keyboardType: TextInputType.number,
                              readOnly: true,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    key: ValueKey('asm_$_selectedAssembly'),
                                    initialValue: _selectedAssembly,
                                    decoration: const InputDecoration(
                                      labelText: 'Assembly',
                                      filled: true,
                                    ),
                                    readOnly: true,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    key: ValueKey('sec_$_selectedSection'),
                                    initialValue: _selectedSection,
                                    decoration: const InputDecoration(
                                      labelText: 'Section',
                                      filled: true,
                                    ),
                                    readOnly: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            CheckboxListTile(
                              title: const Text(
                                'Borrowed valve from another Assembly?',
                              ),
                              contentPadding: EdgeInsets.zero,
                              value: _isBorrowed,
                              onChanged: (value) {
                                setState(() {
                                  _isBorrowed = value ?? false;
                                  if (_isBorrowed &&
                                      _borrowedFromAssembly == null) {
                                    _borrowedFromAssembly =
                                        _assemblies
                                            .where(
                                              (a) => a != _selectedAssembly,
                                            )
                                            .firstOrNull ??
                                        _assemblies.first;
                                  }
                                });
                              },
                            ),
                            if (_isBorrowed)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: DropdownButtonFormField<String>(
                                  initialValue: _borrowedFromAssembly,
                                  decoration: const InputDecoration(
                                    labelText: 'Source Assembly',
                                  ),
                                  items: _assemblies
                                      .where((a) => a != _selectedAssembly)
                                      .map((a) {
                                        return DropdownMenuItem(
                                          value: a,
                                          child: Text('Asm $a'),
                                        );
                                      })
                                      .toList(),
                                  onChanged: (value) => setState(
                                    () => _borrowedFromAssembly = value!,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _signController,
                              decoration: const InputDecoration(
                                labelText: 'Signature / Name',
                                filled: true,
                              ),
                              readOnly: true,
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              title: const Text('Take Time'),
                              subtitle: Text(
                                _takeTime != null
                                    ? DateFormat(
                                        'MMM dd, yyyy - hh:mm a',
                                      ).format(_takeTime!)
                                    : 'Not set',
                              ),
                              trailing: const Icon(Icons.access_time),
                              onTap: () => _selectDateTime(context, true),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              title: const Text('Submit Time'),
                              subtitle: Text(
                                _submitTime != null
                                    ? DateFormat(
                                        'MMM dd, yyyy - hh:mm a',
                                      ).format(_submitTime!)
                                    : 'Not set',
                              ),
                              trailing: const Icon(Icons.access_time),
                              onTap: () => _selectDateTime(context, false),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveEntry,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                      ),
                      child: const Text('SAVE', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SafeArea(child: BannerAdWidget()),
        ],
      ),
    );
  }
}
